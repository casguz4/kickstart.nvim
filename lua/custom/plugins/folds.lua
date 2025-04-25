return {
  'kevinhwang91/nvim-ufo',
  dependencies = {
    'kevinhwang91/promise-async',
  },
  config = function()
    -- Tell the server the capability of foldingRange,
    -- Neovim hasn't added foldingRange to default capabilities, users must add it manually
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    -- this isn't needed because of vim.lsp.enable (i think)
    -- local language_servers = vim.lsp.get_clients()
    -- for _, ls in ipairs(language_servers) do
    --   require('lspconfig')[ls].setup {
    --     capabilities = capabilities,
    --     -- you can add other fields for setting up lsp server in this table
    --   }
    -- end
    require('ufo').setup {
      vim.keymap.set('n', 'zR', require('ufo').openAllFolds),
      vim.keymap.set('n', 'zM', require('ufo').closeAllFolds),
    }
  end,
}
