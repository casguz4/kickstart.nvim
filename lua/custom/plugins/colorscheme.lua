return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000, -- load before eveything else
  config = function()
    vim.cmd.colorscheme 'catppuccin'
  end,
}
