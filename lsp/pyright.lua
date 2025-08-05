---@type vim.lsp.Config
return {
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
    '.git',
  },
  settings = {
    python = {
      analysis = {
        -- Type checking
        typeCheckingMode = 'basic', -- off, basic, strict
        diagnosticMode = 'workspace', -- openFilesOnly, workspace
        
        -- Auto-import
        autoImportCompletions = true,
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        
        -- Diagnostics
        diagnosticSeverityOverrides = {
          reportUnusedImport = 'information',
          reportUnusedClass = 'information',
          reportUnusedFunction = 'information',
          reportUnusedVariable = 'information',
          reportDuplicateImport = 'warning',
        },
        
        -- Inlay hints
        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = 'partial',
          parameterTypes = true,
          pytestParameters = true,
        },
        
        -- Import resolution
        extraPaths = {},
        stubPath = 'typings',
        
        -- Code completion
        completeFunctionParens = true,
        
        -- Indexing
        indexing = true,
        
        -- Log level
        logLevel = 'Information',
      },
      
      -- Linting (if using pylsp as alternative)
      linting = {
        enabled = true,
        pylintEnabled = false,
        flake8Enabled = false,
        mypyEnabled = false,
        banditEnabled = false,
        pydocstyleEnabled = false,
        pycodestyleEnabled = false,
        pyflakesEnabled = false,
      },
      
      -- Formatting (if using pylsp)
      formatting = {
        provider = 'black',
        blackArgs = { '--line-length=88' },
        autopep8Args = {},
        yapfArgs = {},
      },
      
      -- Workspace configuration
      workspaceSymbolsMaxResults = 1000,
    },
  },
  
  -- Additional initialization options
  init_options = {
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = 'workspace',
        },
      },
    },
  },
}
