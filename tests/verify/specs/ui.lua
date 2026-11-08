local h = ...

-- Fire an LspProgress event the way the LSP client does when a server sends
-- `$/progress`. `client_id` is never looked up by the bridge, so no server is
-- needed.
local function lsp_progress(token, value)
  vim.api.nvim_exec_autocmds('LspProgress', {
    pattern = value.kind,
    modeline = false,
    data = { client_id = 0, params = { token = token, value = value } },
  })
end

local function statusline()
  return vim.api.nvim_eval_statusline(vim.o.statusline, { winid = vim.api.nvim_get_current_win() }).str
end

h.test('ui: LSP progress is echoed to the cmdline (messagesopt progress:c)', function()
  h.ok(vim.o.messagesopt:find('progress:c', 1, true), "messagesopt lacks 'progress:c': " .. vim.o.messagesopt)
  local seen = {}
  local id = vim.api.nvim_create_autocmd('Progress', {
    callback = function(ev)
      table.insert(seen, ev.data)
    end,
  })
  lsp_progress('verify-ui-echo', { kind = 'begin', title = 'Indexing', message = 'files', percentage = 10 })
  lsp_progress('verify-ui-echo', { kind = 'end', message = 'done' })
  vim.api.nvim_del_autocmd(id)
  h.eq(#seen, 2, 'progress messages echoed for one begin + end')
  h.eq(seen[1] and seen[1].status, 'running', 'status of the begin message')
  h.eq(seen[2] and seen[2].status, 'success', 'status of the end message')
end)

-- The progress status reads "<avg>%(<count>)". Servers from earlier tests may
-- still be reporting, so compare the count with what was running before. No
-- event is processed between these synchronous calls, so nothing else changes
-- it meanwhile.
local function running_count(line)
  return tonumber(line:match '%d+%%%((%d+)%)') or 0
end

h.test('ui: statusline shows LSP progress while it runs', function()
  h.open 'lua/sample.lua'
  local token = 'verify-ui-progress'
  local before = running_count(statusline()) -- the first render starts progress tracking
  lsp_progress(token, { kind = 'begin', title = 'Indexing', percentage = 40 })
  local running = statusline()
  lsp_progress(token, { kind = 'end', message = 'done' })
  local done = statusline()
  h.eq(running_count(running), before + 1, 'running progress count in the statusline: ' .. running)
  h.eq(running_count(done), before, 'progress count after it ended: ' .. done)
end)

h.test('ui: diagnostics show virtual lines on the cursor line, virtual text elsewhere', function()
  local config = vim.diagnostic.config() or {}
  h.eq(config.virtual_lines, { current_line = true }, 'virtual_lines')
  local vt = config.virtual_text
  h.ok(type(vt) == 'table', 'virtual_text is not a table: ' .. vim.inspect(vt))
  h.eq(vt.source, 'if_many', 'virtual_text.source')
  h.eq(vt.spacing, 2, 'virtual_text.spacing')
  h.eq(vt.current_line, false, 'virtual_text.current_line')
end)

h.test('ui: bufferline leaves room for neo-tree, labelled File Explorer', function()
  h.open 'lua/sample.lua'
  vim.cmd 'topleft vsplit'
  local tree_win = vim.api.nvim_get_current_win()
  local tree_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(tree_win, tree_buf)
  vim.bo[tree_buf].filetype = 'neo-tree'
  vim.cmd 'wincmd l'
  local ok, tabline = pcall(function()
    return vim.api.nvim_eval_statusline(vim.o.tabline, { use_tabline = true }).str
  end)
  vim.api.nvim_win_close(tree_win, true)
  vim.api.nvim_buf_delete(tree_buf, { force = true })
  h.ok(ok, 'tabline failed to render: ' .. tostring(tabline))
  h.ok(tabline:find('File Explorer', 1, true), 'tabline has no "File Explorer" offset: ' .. tabline)
end)
