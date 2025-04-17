return {
  'ray-x/go.nvim',
  dependencies = { 'ray-x/guihua.lua' },
  config = function()
    require('go').setup {
      lsp_cfg = true, -- Enable LSP
      lsp_gofumpt = true, -- Use gofumpt for formatting instead of gofmt
      lsp_on_attach = true, -- Use default on_attach
      dap_debug = true, -- Enable DAP debugging
    }

    -- Keymap for testing Go files
    vim.keymap.set('n', '<leader>gt', '<cmd>GoTest<CR>', { desc = 'Run Go Tests' })
  end,
}
