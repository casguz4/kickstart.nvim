local hints = {
  constantValues = true,
  parameterNames = true,
  rangeVariableTypes = true,
  assignVariableTypes = true,
  compositeLiteralTypes = true,
  functionTypeParameters = true,
  compositeLiteralFields = true,
}

---@type vim.lsp.Config
return {
  root_markers = {
    'go.work',
    'go.mod',
    '.git',
  },
  settings = {
    gopls = {
      hints = hints,
      
      -- Build configuration
      buildFlags = { '-tags=integration,e2e' },
      env = {
        GOFLAGS = '-tags=integration,e2e',
      },
      
      -- Static analysis
      staticcheck = true,
      vulncheck = 'Imports',
      
      -- Analyses
      analyses = {
        fillreturns = true,
        nonewvars = true,
        shadow = true,
        simplifycompositelit = true,
        simplifyrange = true,
        simplifyslice = true,
        sortslice = true,
        undeclaredname = true,
        unreachable = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      
      -- Code lens
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      
      -- Completion settings
      completeUnimported = true,
      usePlaceholders = true,
      completionDocumentation = true,
      
      -- Import organization
      gofumpt = true,
      
      -- Workspace configuration
      expandWorkspaceToModule = true,
      experimentalWorkspaceModule = true,
      
      -- Semantic tokens
      semanticTokens = true,
      
      -- Diagnostics
      diagnosticsDelay = '250ms',
      
      -- Matching
      matcher = 'Fuzzy',
      symbolMatcher = 'FastFuzzy',
      symbolStyle = 'Dynamic',
    },
  },
}
