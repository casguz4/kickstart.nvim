-- inspired by @stephansama github.com/stephansama/nvim/lua/plugins/editor/mason.lua
local MASON_ENSURED = {
  -- LSP servers
  'bash-language-server',
  'css-lsp',
  'dockerfile-language-server',
  'emmet-ls',
  'eslint-lsp',
  'gopls',
  'html-lsp',
  'json-lsp',
  'lua-language-server',
  'typescript-language-server',
  'vue-language-server',

  -- Markdown
  'markdownlint',
  'marksman',

  -- Formatters
  'prettier',
  'prettierd',

  -- Debuggers for frontend
  'js-debug-adapter',
  'chrome-debug-adapter',

  -- Linters for frontend
  'eslint_d',
  'stylelint',
  'jsonlint',
  'yamllint',
}

local function MasonInstallAll()
  if MASON_ENSURED and #MASON_ENSURED > 0 then
    vim.cmd('MasonInstall ' .. table.concat(MASON_ENSURED, ' '))
  end
end

local ts_inlay_hints = {
  includeInlayVariableTypeHints = true,
  includeInlayParameterNameHints = 'all',
  includeInlayEnumMemberValueHints = true,
  includeInlayFunctionParameterTypeHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayVariableTypeHintsWhenTypeMatchesName = false,
  includeInlayParameterNameHintsWhenArgumentMatchesName = false,
}

return {
  -- Main LSP Configuration (uses Neovim 0.11+ native `vim.lsp.config()` + `vim.lsp.enable()`)
  'neovim/nvim-lspconfig',
  dependencies = {
    {
      'kevinhwang91/nvim-ufo',
      dependencies = { 'kevinhwang91/promise-async' },
      config = function()
        local ufo = require 'ufo'

        vim.keymap.set('n', 'zR', ufo.openAllFolds, { desc = 'Open all folds' })
        vim.keymap.set('n', 'zM', ufo.closeAllFolds, { desc = 'Close all folds' })

        local function chained_providers(bufnr)
          local function handle_fallback(err, provider)
            if type(err) == 'string' and err:match 'UfoFallbackException' then
              return ufo.getFolds(bufnr, provider)
            end
            return require('promise').reject(err)
          end

          return ufo
            .getFolds(bufnr, 'lsp')
            :catch(function(err)
              return handle_fallback(err, 'treesitter')
            end)
            :catch(function(err)
              return handle_fallback(err, 'indent')
            end)
        end

        ufo.setup {
          provider_selector = function(bufnr)
            return function()
              return chained_providers(bufnr)
            end
          end,
        }
      end,
    },

    -- Mason (installs external language servers/tools)
    {
      'mason-org/mason.nvim',
      opts = {
        PATH = 'prepend',
        registries = { 'github:mason-org/mason-registry' },
        ui = { border = 'rounded' },
      },
      config = function(_, opts)
        require('mason').setup(opts)
        vim.api.nvim_create_user_command('MasonInstallAll', MasonInstallAll, { desc = 'Install all Mason tools' })
      end,
    },

    {
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      opts = {
        ensure_installed = MASON_ENSURED,
        run_on_start = true,
        start_delay = 3000,
      },
      config = true,
    },

    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by blink.cmp
    'saghen/blink.cmp',
  },

  config = function()
    -- Diagnostics
    -- See :help vim.diagnostic.Opts
    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      } or {},
      virtual_text = {
        source = 'if_many',
        spacing = 2,
      },
    }

    -- Keymaps + buffer-local LSP settings
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('custom-lsp-attach', { clear = true }),
      callback = function(args)
        local bufnr = args.buf

        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map('n', 'gd', vim.lsp.buf.definition, 'LSP: Go to definition')
        map('n', 'gD', vim.lsp.buf.declaration, 'LSP: Go to declaration')
        map('n', 'gI', vim.lsp.buf.implementation, 'LSP: Go to implementation')
        map('n', 'gr', vim.lsp.buf.references, 'LSP: References')
        map('n', 'K', vim.lsp.buf.hover, 'LSP: Hover')
        map('n', '<leader>rn', vim.lsp.buf.rename, 'LSP: Rename')
        map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'LSP: Code action')
        map('n', '[d', vim.diagnostic.goto_prev, 'Diagnostics: Previous')
        map('n', ']d', vim.diagnostic.goto_next, 'Diagnostics: Next')
        map('n', '<leader>e', vim.diagnostic.open_float, 'Diagnostics: Float')

        local client_id = args.data and args.data.client_id
        local client = client_id and vim.lsp.get_client_by_id(client_id) or nil
        if client and client.supports_method 'textDocument/inlayHint' then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end,
    })

    -- Capabilities
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('blink.cmp').get_lsp_capabilities({}, false))
    capabilities = vim.tbl_deep_extend('force', capabilities, {
      textDocument = {
        foldingRange = {
          dynamicRegistration = false,
          lineFoldingOnly = true,
        },
      },
    })

    -- Default settings for all LSP configs loaded from runtimepath (including nvim-lspconfig's `lsp/*.lua`).
    vim.lsp.config('*', { capabilities = capabilities })

    -- Per-server overrides (stays "native" via vim.lsp.config)
    vim.lsp.config('bashls', {
      filetypes = { 'bash', 'sh', 'zsh' },
    })

    vim.lsp.config('gopls', {
      settings = {
        gopls = {
          hints = {
            constantValues = true,
            parameterNames = true,
            rangeVariableTypes = true,
            assignVariableTypes = true,
            compositeLiteralTypes = true,
            functionTypeParameters = true,
            compositeLiteralFields = true,
          },
        },
      },
    })

    vim.lsp.config('ts_ls', {
      settings = {
        javascript = { inlayHints = ts_inlay_hints },
        typescript = { inlayHints = ts_inlay_hints },
      },
    })

    -- Enable servers
    local ts_server = (vim.env.TSGOPATH and vim.env.TSGOPATH ~= '') and 'tsgo' or 'ts_ls'

    vim.lsp.enable {
      'lua_ls',
      'gopls',
      ts_server,
      'bashls',
      'html',
      'cssls',
      'jsonls',
      'emmet_ls',
      'eslint',
      'volar',
    }
  end,
}
