---@type vim.lsp.Config
return {
  root_markers = {
    'package.json',
    '.git',
  },
  settings = {
    html = {
      validate = true,
      completion = {
        attributeDefaultValue = 'doublequotes',
      },
      format = {
        enable = true,
        wrapLineLength = 120,
        unformatted = 'wbr',
        contentUnformatted = 'pre,code,textarea',
        indentInnerHtml = false,
        preserveNewLines = true,
        maxPreserveNewLines = 2,
        indentHandlebars = false,
        endWithNewline = false,
        extraLiners = 'head, body, /html',
        wrapAttributes = 'auto',
        templating = false,
        unformattedContentDelimiter = '',
      },
      hover = {
        documentation = true,
        references = true,
      },
      suggest = {
        html5 = true,
        angular1 = false,
        ionic = false,
      },
      trace = {
        server = 'off',
      },
      autoClosingTags = true,
      mirrorCursorOnMatchingTag = false,
    },
  },
  init_options = {
    embeddedLanguages = {
      css = true,
      javascript = true,
    },
    configurationSection = { 'html', 'css', 'javascript' },
    provideFormatter = true,
  },
}
