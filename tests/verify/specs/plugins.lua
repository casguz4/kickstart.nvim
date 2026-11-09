local h = ...

-- Plugins no other area owns. A plugin that belongs to an area (completion,
-- ui, servers, ...) is listed in that area's spec, with the ones it replaced,
-- so tickets in different areas don't edit one shared list.
h.test('plugins: the plugins no area owns are installed', function()
  h.expect_plugins {
    installed = {
      'fzf-lua',
      'gitsigns.nvim',
      'lazy.nvim',
      'mini.nvim',
      'nvim-autopairs',
      'nvim-treesitter',
      'nvim-ts-autotag',
      'plenary.nvim',
      'todo-comments.nvim',
      'vim-sleuth',
      'which-key.nvim',
    },
  }
end)

h.test('plugins: mini.nvim modules are set up', function()
  h.ok(h.map('n', 'gsa'), 'gsa (mini.surround add) is not mapped')
  h.ok(h.map('o', 'a'), 'a (mini.ai textobjects) is not mapped in operator-pending mode')
  h.ok(vim.o.statusline:find('MiniStatusline', 1, true), 'statusline is not mini.statusline: ' .. vim.o.statusline)
end)
