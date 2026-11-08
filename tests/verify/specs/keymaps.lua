local h = ...

h.test('keymaps: <leader>q opens the diagnostic loclist', function()
  local m = h.map('n', '<leader>q')
  h.ok(m, '<leader>q is not mapped')
  h.eq(m.desc, 'Open diagnostic [Q]uickfix list', '<leader>q desc')
end)

h.test('keymaps: gd jumps to definition in an LSP buffer', function()
  h.expect_servers('lua/sample.lua', { includes = { 'lua_ls' } })
  local m = h.map('n', 'gd', vim.api.nvim_get_current_buf())
  h.ok(m and m.buffer == 1, 'gd is not mapped in the LSP buffer: ' .. vim.inspect(m))
end)

-- 0.12's own diagnostic jumps, by the descriptions its runtime gives them.
local diagnostic_defaults = {
  { lhs = '[d', desc = 'Jump to the previous diagnostic in the current buffer' },
  { lhs = ']d', desc = 'Jump to the next diagnostic in the current buffer' },
}

for _, case in ipairs(diagnostic_defaults) do
  local lhs, desc = case.lhs, case.desc
  h.test('keymaps: ' .. lhs .. ' is the 0.12 default in an LSP buffer', function()
    h.expect_servers('lua/sample.lua', { includes = { 'lua_ls' } })
    local m = h.map('n', lhs, vim.api.nvim_get_current_buf())
    h.ok(m, lhs .. ' is not mapped')
    h.ok(m.buffer == 0, lhs .. ' is overridden by a buffer-local map: ' .. tostring(m.desc))
    h.eq(m.desc, desc, lhs .. ' desc')
  end)
end
