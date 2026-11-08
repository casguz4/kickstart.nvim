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
