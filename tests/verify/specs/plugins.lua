local h = ...

-- Plugins the 0.11 config ships today. Migration tickets move entries from
-- here to `absent` as they remove plugins, and add the ones they introduce.
local present = {
  'CopilotChat.nvim',
  'LuaSnip',
  'blink.cmp',
  'bufferline.nvim',
  'catppuccin',
  'conform.nvim',
  'copilot.vim',
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
  'nvim-lint',
  'nvim-lspconfig',
  'nvim-nio',
  'nvim-treesitter',
  'nvim-ts-autotag',
  'nvim-ufo',
  'nvim-web-devicons',
  'plenary.nvim',
  'promise-async',
  'todo-comments.nvim',
  'vim-sleuth',
  'which-key.nvim',
}

local absent = {}

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
