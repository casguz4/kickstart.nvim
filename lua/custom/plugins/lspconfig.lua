-- inspired by @stephansama github.com/stephansama/nvim/lua/plugins/editor/mason.lua
local MASON_ENSURED = {
  -- LSP servers
  'astro-language-server',
  'bash-language-server',
  'clangd',
  'css-lsp',
  'dockerfile-language-server',
  'emmet-ls',
  'eslint-lsp',
  'gopls',
  'html-lsp',
  'json-lsp',
  'lua-language-server',
  'rust-analyzer',
  'stylelint-language-server',
  'svelte-language-server',
  'tsc',
  'vtsls',
  'vue-language-server',
  'yaml-language-server',

  -- Markdown
  'marksman',
  'rumdl',

  -- Formatters
  'prettier',
  'prettierd',
  'stylua',

  -- Debug adapters
  'delve',
  'js-debug-adapter',
}

local function MasonInstallAll()
  if MASON_ENSURED and #MASON_ENSURED > 0 then
    vim.cmd('MasonInstall ' .. table.concat(MASON_ENSURED, ' '))
  end
end

return {
  -- Main LSP Configuration (uses Neovim 0.11+ native `vim.lsp.config()` + `vim.lsp.enable()`)
  'neovim/nvim-lspconfig',
  dependencies = {
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

    -- JSON/YAML schemas for jsonls and yamlls.
    'b0o/SchemaStore.nvim',

    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- Loads first, so its completion capabilities are on '*' before servers start.
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
          vim.keymap.set(mode, lhs, rhs, { buf = bufnr, desc = desc })
        end

        map('n', 'gd', vim.lsp.buf.definition, 'LSP: Go to definition')
        map('n', 'gD', vim.lsp.buf.declaration, 'LSP: Go to declaration')
        -- References, implementation, rename, code action, hover etc. use the
        -- 0.12 defaults: grr, gri, grn, gra, grt, grx, gO, K, insert <C-S>.
        map('n', '<leader>e', vim.diagnostic.open_float, 'Diagnostics: Float')

        local client_id = args.data and args.data.client_id
        local client = client_id and vim.lsp.get_client_by_id(client_id) or nil
        if client and client:supports_method 'textDocument/inlayHint' then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end,
    })

    -- Folding: a server with folding ranges takes over from treesitter/indent
    -- in every window showing the buffer, and closes the imports on open.
    local folding = vim.api.nvim_create_augroup('custom-lsp-folding', { clear = true })
    vim.api.nvim_create_autocmd('LspAttach', {
      group = folding,
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not (client and client:supports_method('textDocument/foldingRange', args.buf)) then
          return
        end
        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
          vim.wo[win][0].foldmethod = 'expr'
          vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
        end
      end,
    })
    vim.api.nvim_create_autocmd('LspNotify', {
      group = folding,
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if args.data.method ~= 'textDocument/didOpen' or not (client and client:supports_method('textDocument/foldingRange', args.buf)) then
          return
        end
        -- A client's didOpen goes out before its LspAttach, when LSP folding
        -- hasn't started for the buffer and foldclose() does nothing. Evaluating
        -- the foldexpr starts it on the next tick; close the imports after that.
        vim.api.nvim_buf_call(args.buf, function()
          vim.lsp.foldexpr(1)
        end)
        vim.schedule(function()
          local win = vim.fn.bufwinid(args.buf)
          if win ~= -1 then
            vim.lsp.foldclose('imports', win)
          end
        end)
      end,
    })

    -- Formatting belongs to Prettier (through conform) and stylua, so no other
    -- server may format: conform's `lsp_format = 'prefer'` would pick it over
    -- Prettier. Servers with a setting that stops them advertising formatting
    -- use it (below); the rest drop their formatting capabilities here. vue_ls
    -- formats .vue too, and Prettier owns .vue.
    local function no_formatting(client)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end
    for _, name in ipairs { 'tsc', 'vtsls', 'vue_ls', 'rumdl' } do
      vim.lsp.config(name, { on_init = no_formatting })
    end
    vim.lsp.config('eslint', { settings = { format = false } })
    for _, name in ipairs { 'cssls', 'html', 'jsonls' } do
      vim.lsp.config(name, { init_options = { provideFormatter = false } })
    end
    -- yamlls: lspconfig turns its formatter on and forces the capability on in
    -- `on_init`; replace both.
    vim.lsp.config('yamlls', { settings = { yaml = { format = { enable = false } } }, on_init = no_formatting })

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

    -- TypeScript 7 (`tsc --lsp`) serves JS/TS. Name hints for every argument,
    -- not just literals; everything else stays on lspconfig's `tsc` defaults.
    vim.lsp.config('tsc', {
      settings = {
        ['js/ts'] = { inlayHints = { parameterNames = { enabled = 'all' } } },
      },
    })

    -- Vue: TypeScript 7 can't host `@vue/typescript-plugin` yet, so `.vue` files
    -- get vtsls (TS 6) with the plugin, alongside vue_ls for the template/style
    -- sections. vtsls serves `.vue` only; `.ts` stays on tsc. Setup follows
    -- https://github.com/vuejs/language-tools/wiki/Neovim
    vim.lsp.config('vtsls', {
      filetypes = { 'vue' },
      settings = {
        vtsls = {
          tsserver = {
            globalPlugins = {
              {
                name = '@vue/typescript-plugin',
                location = vim.fn.expand '$MASON/packages/vue-language-server/node_modules/@vue/language-server',
                languages = { 'vue' },
                configNamespace = 'typescript',
              },
            },
          },
        },
      },
    })

    -- Diagnostics come only from language servers (no nvim-lint). eslint and
    -- stylelint_lsp attach only where the project has an ESLint/Stylelint config.
    -- eslint also needs ESLint installed (`node_modules/eslint` above the
    -- buffer): with only a config it can't lint or fix, so it doesn't attach.
    local eslint_root_dir = vim.lsp.config.eslint.root_dir
    vim.lsp.config('eslint', {
      root_dir = function(bufnr, on_dir)
        for dir in vim.fs.parents(vim.api.nvim_buf_get_name(bufnr)) do
          if vim.uv.fs_stat(dir .. '/node_modules/eslint') then
            return eslint_root_dir(bufnr, on_dir)
          end
        end
      end,
    })

    -- stylelint lints css/postcss by default; add scss and less. It attaches to
    -- those filetypes only: lspconfig's list also has html/vue/astro, which
    -- `validate` doesn't cover, so it would attach there and check nothing.
    vim.lsp.config('stylelint_lsp', {
      filetypes = { 'css', 'scss', 'less' },
      settings = {
        stylelint = { validate = { 'css', 'postcss', 'scss', 'less' } },
      },
    })

    -- JSON/YAML: schemas from SchemaStore.nvim, matched by file name. yamlls's
    -- own store is off so SchemaStore.nvim is the only source.
    vim.lsp.config('jsonls', {
      settings = {
        json = {
          schemas = require('schemastore').json.schemas(),
          validate = { enable = true },
        },
      },
    })

    vim.lsp.config('yamlls', {
      settings = {
        yaml = {
          schemaStore = { enable = false, url = '' },
          schemas = require('schemastore').yaml.schemas(),
        },
      },
    })

    -- Markdown: rumdl lints; marksman owns links and symbols, so rumdl's are off.
    vim.lsp.config('rumdl', {
      init_options = {
        enableLinkCompletions = false,
        enableLinkNavigation = false,
        enableSymbols = false,
      },
    })

    -- Enable servers
    vim.lsp.enable {
      'astro',
      'lua_ls',
      'stylua',
      'gopls',
      'clangd',
      'rust_analyzer',
      'svelte',
      'tsc',
      'bashls',
      'html',
      'cssls',
      'jsonls',
      'yamlls',
      'rumdl',
      'marksman',
      'emmet_ls',
      'eslint',
      'stylelint_lsp',
      'vtsls',
      'vue_ls',
    }
  end,
}
