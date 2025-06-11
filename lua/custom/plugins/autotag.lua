return {
  'windwp/nvim-ts-autotag',
  -- Make sure it loads after nvim-treesitter
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  config = function()
    require('nvim-ts-autotag').setup {
      -- Default options, override as needed
      opts = {
        enable_close = true, -- Auto close tags (e.g., `<div>` becomes `<div></div>`)
        enable_rename = true, -- Auto rename pairs of tags (e.g., change `<div>` to `<p>`, and `</div>` will change to `</p>`)
        enable_close_on_slash = false, -- Auto close when typing `</`
      },
      -- You can override settings for specific filetypes
      -- per_filetype = {
      -- For example, to disable auto-closing for HTML only:
      -- ["html"] = { enable_close = false },
      -- },
      -- Aliases if you have custom languages with similar tag structures
      -- aliases = {
      --   ["your_language_here"] = "html",
      -- },
    }
  end,
  -- It's efficient, so lazy loading isn't strictly necessary, but you can do it
  -- event = "InsertEnter", -- Load when entering insert mode
}
