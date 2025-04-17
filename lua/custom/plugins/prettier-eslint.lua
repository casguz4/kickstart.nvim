return {
  'jose-elias-alvarez/null-ls.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local null_ls = require 'null-ls'
    null_ls.setup {
      sources = {
        null_ls.builtins.formatting.prettier.with {
          filetypes = { 'javascript', 'typescript', 'typescriptreact', 'html', 'css', 'json' },
        },
        null_ls.builtins.diagnostics.eslint_d.with {
          condition = function(utils)
            return utils.root_has_file '.eslintrc.js' or utils.root_has_file '.eslintrc.json'
          end,
        },
      },
    }
  end,
}
