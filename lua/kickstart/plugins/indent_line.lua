return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    config = true,
    opts = {
      scope = { enabled = false },
      exclude = {
        filetypes = {
          "dashboard"
        }
      }
    },
  },
}
