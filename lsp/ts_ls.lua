---@type vim.lsp.Config
local M = {}
local inlayHints = {
  includeInlayVariableTypeHints = true,
  includeInlayParameterNameHints = 'all',
  includeInlayEnumMemberValueHints = true,
  includeInlayFunctionParameterTypeHints = true,
  includeInlayFunctionLikeReturnTypeHints = true,
  includeInlayPropertyDeclarationTypeHints = true,
  includeInlayVariableTypeHintsWhenTypeMatchesName = false,
  includeInlayParameterNameHintsWhenArgumentMatchesName = false,
}

local preferences = {
  -- Import organization
  includePackageJsonAutoImports = 'auto',
  importModuleSpecifier = 'shortest',
  importModuleSpecifierEnding = 'minimal',
  includeAutomaticOptionalChainCompletions = true,
  includeCompletionsForImportStatements = true,
  includeCompletionsWithSnippetText = true,
  
  -- Formatting preferences
  allowIncompleteCompletions = true,
  allowRenameOfImportPath = true,
  displayPartsForJSDoc = true,
  generateReturnInDocTemplate = true,
  includeCompletionsForModuleExports = true,
  includeCompletionsWithClassMemberSnippets = true,
  includeCompletionsWithInsertText = true,
  includeCompletionsWithObjectLiteralMethodSnippets = true,
  providePrefixAndSuffixTextForRename = true,
  provideRefactorNotApplicableReason = true,
  quotePreference = 'auto',
  useLabelDetailsInCompletionEntries = true,
}

M.init_options = {
  plugins = {
    {
      name = '@vue/typescript-plugin',
      location = '/usr/local/lib/node_modules/@vue/typescript-plugin',
      languages = { 'javascript', 'typescript', 'vue' },
    },
  },
  preferences = preferences,
}

M.settings = {
  javascript = {
    inlayHints = inlayHints,
    preferences = preferences,
    suggest = {
      includeCompletionsForModuleExports = true,
      includeAutomaticOptionalChainCompletions = true,
    },
    updateImportsOnFileMove = { enabled = 'always' },
    format = {
      enable = true,
      semicolons = 'insert',
      insertSpaceAfterCommaDelimiter = true,
      insertSpaceAfterKeywordsInControlFlowStatements = true,
      insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
      insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = false,
      insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
      insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
      insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces = false,
      insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = false,
      insertSpaceAfterTypeAssertion = false,
      insertSpaceBeforeFunctionParenthesis = false,
      placeOpenBraceOnNewLineForFunctions = false,
      placeOpenBraceOnNewLineForControlBlocks = false,
    },
  },
  typescript = {
    inlayHints = inlayHints,
    preferences = preferences,
    suggest = {
      includeCompletionsForModuleExports = true,
      includeAutomaticOptionalChainCompletions = true,
      autoImports = true,
    },
    updateImportsOnFileMove = { enabled = 'always' },
    format = {
      enable = true,
      semicolons = 'insert',
      insertSpaceAfterCommaDelimiter = true,
      insertSpaceAfterKeywordsInControlFlowStatements = true,
      insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
      insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = false,
      insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
      insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,
      insertSpaceAfterOpeningAndBeforeClosingTemplateStringBraces = false,
      insertSpaceAfterOpeningAndBeforeClosingJsxExpressionBraces = false,
      insertSpaceAfterTypeAssertion = false,
      insertSpaceBeforeFunctionParenthesis = false,
      placeOpenBraceOnNewLineForFunctions = false,
      placeOpenBraceOnNewLineForControlBlocks = false,
    },
  },
}

return M
