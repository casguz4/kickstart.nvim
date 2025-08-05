---@type vim.lsp.Config
return {
  root_markers = {
    'Cargo.toml',
    'Cargo.lock',
    'rust-project.json',
    '.git',
  },
  settings = {
    ['rust-analyzer'] = {
      -- Cargo configuration
      cargo = {
        allFeatures = true,
        loadOutDirsFromCheck = true,
        buildScripts = {
          enable = true,
        },
        cfgs = {
          debug_assertions = nil,
          miri = nil,
        },
      },
      
      -- Procedural macro support
      procMacro = {
        enable = true,
        ignored = {
          ['async-trait'] = { 'async_trait' },
          ['napi-derive'] = { 'napi' },
          ['async-recursion'] = { 'async_recursion' },
        },
      },
      
      -- Check configuration
      check = {
        command = 'clippy',
        features = 'all',
        extraArgs = {
          '--',
          '-W',
          'clippy::all',
          '-W',
          'clippy::pedantic',
          '-W',
          'clippy::restriction',
          '-W',
          'clippy::nursery',
        },
      },
      
      -- Diagnostics
      diagnostics = {
        enable = true,
        experimental = {
          enable = true,
        },
        disabled = {
          'unresolved-proc-macro',
        },
        remapPrefix = {},
        warningsAsHint = {},
        warningsAsInfo = {},
      },
      
      -- Completion settings
      completion = {
        addCallParentheses = true,
        addCallArgumentSnippets = true,
        postfix = {
          enable = true,
        },
        autoimport = {
          enable = true,
        },
        autoself = {
          enable = true,
        },
        callable = {
          snippets = 'fill_arguments',
        },
      },
      
      -- Assist (code actions)
      assist = {
        importEnforceGranularity = true,
        importPrefix = 'plain',
        importGranularity = 'module',
        importGroup = true,
      },
      
      -- Lens (code lens)
      lens = {
        enable = true,
        debug = {
          enable = true,
        },
        implementations = {
          enable = true,
        },
        run = {
          enable = true,
        },
        methodReferences = {
          enable = true,
        },
        references = {
          adt = {
            enable = true,
          },
          enumVariant = {
            enable = true,
          },
          method = {
            enable = true,
          },
          trait = {
            enable = true,
          },
        },
      },
      
      -- Hover actions
      hover = {
        actions = {
          debug = {
            enable = true,
          },
          enable = true,
          gotoTypeDef = {
            enable = true,
          },
          implementations = {
            enable = true,
          },
          references = {
            enable = true,
          },
          run = {
            enable = true,
          },
        },
        documentation = {
          enable = true,
        },
        links = {
          enable = true,
        },
      },
      
      -- Inlay hints
      inlayHints = {
        bindingModeHints = {
          enable = false,
        },
        chainingHints = {
          enable = true,
        },
        closingBraceHints = {
          enable = true,
          minLines = 25,
        },
        closureReturnTypeHints = {
          enable = 'never',
        },
        lifetimeElisionHints = {
          enable = 'never',
          useParameterNames = false,
        },
        maxLength = 25,
        parameterHints = {
          enable = true,
        },
        reborrowHints = {
          enable = 'never',
        },
        renderColons = true,
        typeHints = {
          enable = true,
          hideClosureInitialization = false,
          hideNamedConstructor = false,
        },
      },
      
      -- Workspace and project discovery
      linkedProjects = {},
      workspace = {
        symbol = {
          search = {
            scope = 'workspace_and_dependencies',
            kind = 'only_types',
          },
        },
      },
      
      -- Semantic highlighting
      semanticHighlighting = {
        strings = {
          enable = true,
        },
      },
      
      -- Typing assistance
      typing = {
        autoClosingAngleBrackets = {
          enable = false,
        },
      },
      
      -- Rustfmt
      rustfmt = {
        extraArgs = {},
        overrideCommand = nil,
        rangeFormatting = {
          enable = false,
        },
      },
      
      -- Import granularity
      imports = {
        granularity = {
          group = 'module',
        },
        prefix = 'plain',
      },
      
      -- Notification settings
      notifications = {
        cargoTomlNotFound = true,
      },
    },
  },
}
