local h = ...

-- tsc analyses the project before answering hint requests; give it the same
-- budget the harness gives a server to attach.
local HINT_TIMEOUT_MS = 20000

-- Text of the inlay hints the client has fetched for a buffer.
local function hint_labels(buf)
  return vim.tbl_map(function(item)
    local label = item.inlay_hint.label
    if type(label) == 'table' then
      label = table.concat(vim.tbl_map(function(part)
        return part.value
      end, label))
    end
    return vim.trim(label)
  end, vim.lsp.inlay_hint.get { bufnr = buf })
end

h.test('hints: .ts names parameters for non-literal arguments', function()
  h.expect_servers('src/index.ts', { includes = { 'tsc' } })
  local buf = vim.api.nvim_get_current_buf()
  -- `greet(visitor)` passes a variable, which lspconfig's default ('literals') leaves unnamed.
  local found = vim.wait(HINT_TIMEOUT_MS, function()
    return vim.list_contains(hint_labels(buf), 'name:')
  end, 100)
  h.ok(found, 'no `name:` hint on greet(visitor) (hints: ' .. table.concat(hint_labels(buf), ' | ') .. ')')
end)
