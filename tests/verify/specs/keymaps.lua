local h = ...

-- lua/sample.lua once lua_ls is attached, so LSP buffer maps are in place.
local function lsp_buf()
  h.expect_servers('lua/sample.lua', { includes = { 'lua_ls' } })
  return vim.api.nvim_get_current_buf()
end

h.test('keymaps: <leader>q opens the diagnostic loclist', function()
  h.expect_map('n', '<leader>q', 'Open diagnostic [Q]uickfix list')
end)

h.test('keymaps: gd jumps to definition in an LSP buffer', function()
  local m = h.map('n', 'gd', lsp_buf())
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
    local m = h.expect_map('n', lhs, desc, lsp_buf())
    h.ok(m.buffer == 0, lhs .. ' is overridden by a buffer-local map: ' .. tostring(m.desc))
  end)
end

-- Keys the config used to map itself and now leaves to Neovim. In an LSP
-- buffer these must not be answered by a buffer-local (custom) map.
--
-- 0.12's LSP defaults, by the descriptions its runtime gives them.
local lsp_defaults = {
  { mode = 'n', lhs = 'grr', desc = 'vim.lsp.buf.references()' },
  { mode = 'n', lhs = 'gri', desc = 'vim.lsp.buf.implementation()' },
  { mode = 'n', lhs = 'grn', desc = 'vim.lsp.buf.rename()' },
  { mode = 'n', lhs = 'gra', desc = 'vim.lsp.buf.code_action()' },
  { mode = 'x', lhs = 'gra', desc = 'vim.lsp.buf.code_action()' },
  { mode = 'n', lhs = 'grt', desc = 'vim.lsp.buf.type_definition()' },
  { mode = 'n', lhs = 'grx', desc = 'vim.lsp.codelens.run()' },
  { mode = 'n', lhs = 'gO', desc = 'vim.lsp.buf.document_symbol()' },
  { mode = 'i', lhs = '<C-S>', desc = 'vim.lsp.buf.signature_help()' },
}

for _, case in ipairs(lsp_defaults) do
  local mode, lhs, desc = case.mode, case.lhs, case.desc
  h.test(('keymaps: %s %s is the 0.12 LSP default'):format(mode, lhs), function()
    h.expect_map(mode, lhs, desc, lsp_buf())
  end)
end

h.test('keymaps: K is the 0.12 LSP hover, not a custom map', function()
  h.expect_map('n', 'K', 'vim.lsp.buf.hover()', lsp_buf())
end)

-- Old custom maps whose keys now fall back to core Vim (gr, gI) or to nothing.
local removed = {
  { mode = 'n', lhs = 'gr' },
  { mode = 'n', lhs = 'gI' },
  { mode = 'n', lhs = '<leader>rn' },
  { mode = 'n', lhs = '<leader>ca' },
  { mode = 'x', lhs = '<leader>ca' },
}

for _, case in ipairs(removed) do
  local mode, lhs = case.mode, case.lhs
  h.test(('keymaps: %s %s is no longer a custom LSP map'):format(mode, lhs), function()
    local m = h.map(mode, lhs, lsp_buf())
    h.ok(not m, lhs .. ' is still mapped: ' .. tostring(m and m.desc))
  end)
end

local kept = {
  { lhs = 'gd', desc = 'LSP: Go to definition' },
  { lhs = 'gD', desc = 'LSP: Go to declaration' },
  { lhs = '<leader>e', desc = 'Diagnostics: Float' },
}

for _, case in ipairs(kept) do
  local lhs, desc = case.lhs, case.desc
  h.test('keymaps: ' .. lhs .. ' stays mapped in an LSP buffer', function()
    local m = h.expect_map('n', lhs, desc, lsp_buf())
    h.ok(m.buffer == 1, lhs .. ' is not a buffer-local map: ' .. vim.inspect(m))
  end)
end

-- fzf-lua loads on its keys, so load it first: then each key holds its real
-- command instead of lazy.nvim's loader stub.
local function fzf_map(lhs)
  require('lazy').load { plugins = { 'fzf-lua' } }
  return h.map('n', lhs)
end

h.test('keymaps: <leader>sb opens FzfLua buffers', function()
  local m = fzf_map '<leader>sb'
  h.ok(m, '<leader>sb is not mapped')
  h.eq(m.rhs, '<cmd>FzfLua buffers<CR>', '<leader>sb rhs')
end)

h.test('keymaps: <leader>b no longer opens FzfLua buffers', function()
  local m = fzf_map '<leader>b'
  h.ok(not (m and m.rhs == '<cmd>FzfLua buffers<CR>'), '<leader>b still opens FzfLua buffers')
end)

h.test('keymaps: <leader>b is the [B]uffer which-key group', function()
  h.eq(h.key_group '<leader>b', '[B]uffer', '<leader>b group')
end)

h.test('keymaps: <leader>d is the [D]ebug which-key group', function()
  h.eq(h.key_group '<leader>d', '[D]ebug', '<leader>d group')
end)

local bufferline_keys = {
  { lhs = '<leader>bl', rhs = ':BufferLineMoveNext<CR>' },
  { lhs = '<leader>bh', rhs = ':BufferLineMovePrev<CR>' },
  { lhs = '<leader>bc', rhs = ':BufferLinePickClose<CR>' },
  { lhs = '<leader>bx', rhs = ':bdelete<CR>' },
  { lhs = '<leader>bp', rhs = ':BufferLinePick<CR>' },
}

for _, case in ipairs(bufferline_keys) do
  local lhs, rhs = case.lhs, case.rhs
  h.test('keymaps: ' .. lhs .. ' stays a buffer key', function()
    local m = h.map('n', lhs)
    h.ok(m, lhs .. ' is not mapped')
    h.eq(m.rhs, rhs, lhs .. ' rhs')
  end)
end

h.test('keymaps: <leader>S saves and quits all', function()
  local m = h.map('n', '<leader>S')
  h.ok(m, '<leader>S is not mapped')
  h.eq(m.rhs, '<cmd>wqa<CR>', '<leader>S rhs')
end)
