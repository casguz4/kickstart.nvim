local h = ...

-- Plugins the config ships today. Migration tickets move entries from
-- here to `absent` as they remove plugins, and add the ones they introduce.
local present = {
  'SchemaStore.nvim',
  'blink.cmp',
  'bufferline.nvim',
  'catppuccin',
  'claudecode.nvim',
  'conform.nvim',
  'dashboard-nvim',
  'fidget.nvim',
  'friendly-snippets',
  'fzf-lua',
  'gitsigns.nvim',
  'indent-blankline.nvim',
  'lazy.nvim',
  'lazydev.nvim',
  'mason-nvim-dap.nvim',
  'mason-tool-installer.nvim',
  'mason.nvim',
  'mini.nvim',
  'neo-tree.nvim',
  'nui.nvim',
  'nvim-autopairs',
  'nvim-dap',
  'nvim-dap-go',
  'nvim-dap-ui',
  'nvim-lspconfig',
  'nvim-nio',
  'nvim-treesitter',
  'nvim-ts-autotag',
  'nvim-web-devicons',
  'plenary.nvim',
  'todo-comments.nvim',
  'vim-sleuth',
  'which-key.nvim',
}

local absent = {
  'CopilotChat.nvim',
  'LuaSnip',
  'copilot.vim',
  'nvim-lint',
  'nvim-ufo',
  'promise-async',
}

for _, name in ipairs(present) do
  h.test('plugins: ' .. name .. ' is installed', function()
    h.ok(h.plugin(name), name .. ' is not in the lazy.nvim registry')
  end)
end

for _, name in ipairs(absent) do
  h.test('plugins: ' .. name .. ' is removed', function()
    h.ok(not h.plugin(name), name .. ' is still in the lazy.nvim registry')
  end)
end

h.test('plugins: mini.nvim modules are set up', function()
  h.ok(h.map('n', 'gsa'), 'gsa (mini.surround add) is not mapped')
  h.ok(h.map('o', 'a'), 'a (mini.ai textobjects) is not mapped in operator-pending mode')
  h.ok(vim.o.statusline:find('MiniStatusline', 1, true), 'statusline is not mini.statusline: ' .. vim.o.statusline)
end)
