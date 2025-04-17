return {
  {
    'github/copilot.vim',
    config = function()
      -- Optional: Keybindings for GitHub Copilot
      vim.g.copilot_no_tab_map = true
      vim.api.nvim_set_keymap('i', '<C-J>', 'copilot#Accept("<CR>")', { silent = true, expr = true })

      -- Enable Copilot
      vim.cmd 'Copilot enable'
    end,
  },
}
