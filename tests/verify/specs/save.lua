local h = ...

-- Saving runs the fixers (code actions) and then conform. Each case saves a
-- copy of an intentionally messy fixture inside the fixture project and
-- compares the written file with a hand-written expected file.

h.test('save: .lua formats through the stylua server per stylua.toml', function()
  local path = h.sibling_copy 'lua/messy.lua'
  h.expect_servers(path, { includes = { 'stylua' } })
  vim.cmd 'write'
  h.eq(vim.fn.readfile(path), h.expected 'messy.lua', 'saved messy.lua')
end)

-- tsc's organizeImports drops the unused import, eslint's fixAll applies
-- `prefer-const`, then Prettier (defaults: the fixture has no config) formats.
h.test('save: .ts removes the unused import, applies the ESLint fix, formats with Prettier', function()
  local path = h.sibling_copy 'src/messy.ts'
  h.expect_servers(path, { includes = { 'tsc', 'eslint' } })
  vim.cmd 'write'
  h.eq(vim.fn.readfile(path), h.expected 'messy.ts', 'saved messy.ts')
end)

-- A fixer that never answers is given up on after its limit, and the save
-- goes ahead. The fixer is an in-process server that offers `source.fixAll`
-- and never replies to the code-action request.
h.test('save: a fixer that hangs does not block the save', function()
  local FIXER_LIMIT_MS = 1000 -- the per-fixer limit #24 sets
  local asked = false
  local function hanging_server(dispatchers)
    local closing, next_id = false, 0
    return {
      request = function(method, _, callback)
        next_id = next_id + 1
        if method == 'initialize' then
          vim.schedule(function()
            callback(nil, { capabilities = { textDocumentSync = 1, codeActionProvider = { codeActionKinds = { 'source.fixAll' } } } })
          end)
        elseif method == 'textDocument/codeAction' then
          asked = true -- and never answer
        elseif method == 'shutdown' then
          vim.schedule(function()
            callback(nil, nil)
          end)
        end
        return true, next_id
      end,
      notify = function(method)
        if method == 'exit' then
          closing = true
          dispatchers.on_exit(0, 0)
        end
      end,
      is_closing = function()
        return closing
      end,
      terminate = function()
        closing = true
      end,
    }
  end

  local path = vim.fn.tempname() .. '.txt'
  local buf = h.open(path)
  local id = assert(vim.lsp.start({ name = 'hanging-fixer', cmd = hanging_server, root_dir = vim.fs.dirname(path) }, { bufnr = buf }))
  vim.wait(5000, function()
    return vim.lsp.get_client_by_id(id).initialized
  end, 20)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'saved anyway' })

  local start = vim.uv.hrtime()
  vim.cmd 'write'
  local elapsed_ms = (vim.uv.hrtime() - start) / 1e6
  vim.lsp.get_client_by_id(id):stop(true)

  h.ok(asked, 'the hanging fixer was never asked for a code action')
  h.ok(elapsed_ms < FIXER_LIMIT_MS + 500, string.format('save took %d ms (fixer limit is %d ms)', elapsed_ms, FIXER_LIMIT_MS))
  h.eq(vim.fn.readfile(path), { 'saved anyway' }, 'file on disk')
end)
