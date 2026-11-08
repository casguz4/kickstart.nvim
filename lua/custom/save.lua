-- What saving a buffer does: one synchronous BufWritePre that first runs the
-- fixers attached servers offer (code actions), then formats with conform.
--
-- Fixers: every `source.fixAll*` and `source.organizeImports*` kind a server
-- advertises, fixAll kinds first. Language servers fix before linter servers,
-- so a linter fixes code the language server already cleaned up. Each fixer
-- gets FIX_TIMEOUT_MS; one that errors or runs out of time is skipped.
local M = {}

local FIX_TIMEOUT_MS = 1000
local FORMAT_TIMEOUT_MS = 500
local FIX_PREFIXES = { 'source.fixAll', 'source.organizeImports' }
-- Linter servers, in the order they fix. Every other server fixes before them.
local LINTERS = { 'eslint', 'stylelint_lsp', 'rumdl' }
-- Filetypes without a well-standardized style: fix, but don't format.
local NO_FORMAT = { c = true, cpp = true }

-- The fix kinds `client` advertises, fixAll kinds first.
local function fix_kinds(client)
  local provider = client.server_capabilities.codeActionProvider
  local kinds = {}
  for _, prefix in ipairs(FIX_PREFIXES) do
    for _, kind in ipairs(type(provider) == 'table' and provider.codeActionKinds or {}) do
      if kind == prefix or vim.startswith(kind, prefix .. '.') then
        table.insert(kinds, kind)
      end
    end
  end
  return kinds
end

-- Language servers first, then linters in LINTERS order.
local function fix_order(clients)
  local function rank(client)
    for i, name in ipairs(LINTERS) do
      if client.name == name then
        return i
      end
    end
    return 0
  end
  table.sort(clients, function(a, b)
    if rank(a) ~= rank(b) then
      return rank(a) < rank(b)
    end
    return a.id < b.id
  end)
  return clients
end

-- Milliseconds left before `deadline` (an `hrtime` in ms), at least 0.
local function ms_left(deadline)
  return math.max(0, math.floor(deadline - vim.uv.hrtime() / 1e6))
end

-- Apply one code action: its edit (resolving it first when the server sends
-- the edit lazily), then its command, synchronously, all before `deadline`.
local function apply_action(client, action, buf, deadline)
  if not action.edit and not action.command and client:supports_method('codeAction/resolve', buf) then
    local resolved = client:request_sync('codeAction/resolve', action, ms_left(deadline), buf)
    if not (resolved and resolved.result) then
      return
    end
    action = resolved.result
  end
  if action.edit then
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
  end
  local command = type(action.command) == 'table' and action.command or nil
  if command then
    local local_handler = vim.lsp.commands[command.command]
    if local_handler then
      local_handler(command, { bufnr = buf, client_id = client.id })
    elseif ms_left(deadline) > 0 then
      -- The server answers by sending `workspace/applyEdit`, handled while we wait.
      client:request_sync('workspace/executeCommand', command, ms_left(deadline), buf)
    end
  end
end

-- Run one fixer (one fix kind of one server) on `buf` within FIX_TIMEOUT_MS,
-- skipping it silently on error or timeout.
local function run_fix(client, kind, buf)
  local deadline = vim.uv.hrtime() / 1e6 + FIX_TIMEOUT_MS
  -- The whole buffer (a character past the line's end means its end).
  local last = vim.api.nvim_buf_line_count(buf) - 1
  local params = {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    range = {
      start = { line = 0, character = 0 },
      ['end'] = { line = last, character = #vim.api.nvim_buf_get_lines(buf, last, last + 1, true)[1] },
    },
    context = { only = { kind }, diagnostics = {}, triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic },
  }
  local response = client:request_sync('textDocument/codeAction', params, ms_left(deadline), buf)
  if not response or response.err or not response.result then
    return
  end
  for _, action in ipairs(response.result) do
    -- A request for a parent kind also returns its children's actions; those
    -- run under their own kind.
    if action.kind == kind and ms_left(deadline) > 0 then
      apply_action(client, action, buf, deadline)
    end
  end
end

-- Run every fixer the servers attached to `buf` offer.
local function fix(buf)
  for _, client in ipairs(fix_order(vim.lsp.get_clients { bufnr = buf, method = 'textDocument/codeAction' })) do
    for _, kind in ipairs(fix_kinds(client)) do
      pcall(run_fix, client, kind, buf)
    end
  end
end

-- Fix, then format with conform (LSP formatting preferred where a server
-- offers it; Prettier everywhere else it's configured).
local function on_save(buf)
  fix(buf)
  if not NO_FORMAT[vim.bo[buf].filetype] then
    require('conform').format { bufnr = buf, timeout_ms = FORMAT_TIMEOUT_MS, lsp_format = 'prefer' }
  end
end

---Create the BufWritePre autocmd that fixes and formats every save.
function M.setup()
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('custom-save', { clear = true }),
    desc = 'Fix and format on save',
    callback = function(args)
      on_save(args.buf)
    end,
  })
end

return M
