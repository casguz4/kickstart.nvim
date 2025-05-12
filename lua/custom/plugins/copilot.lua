return {
  {
    'github/copilot.vim',
    config = function()
      -- Optional: Keybindings for GitHub Copilot
      vim.g.copilot_no_tab_map = true
      vim.api.nvim_set_keymap('i', '<C-J>', 'copilot#Accept("<CR>")', { silent = true, expr = true })

      -- Enable Copilot; this is optional and i prefer to turn it on when needed which has shown to be **very rare**
      vim.cmd 'Copilot disable'
    end,
  },
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      { 'github/copilot.vim' },
      { 'nvim-lua/plenary.nvim', branch = 'master' },
    },
    build = 'make tiktoken', -- Only on MacOS or Linux
    opts = {
      -- See Configuration section for options
      sticky = {
        "#buffer:`current`",
      },
    },
  },
}
