---@type vim.lsp.Config
return {
  filetypes = {
    'html',
    'css',
    'scss',
    'sass',
    'less',
    'javascriptreact',
    'typescriptreact',
    'vue',
    'svelte',
    'xml',
    'xsl',
    'pug',
    'slim',
    'haml',
    'handlebars',
    'erb',
    'ejs',
    'php',
    'htmldjango',
  },
  root_markers = {
    'package.json',
    '.git',
  },
  init_options = {
    html = {
      options = {
        -- BEM support
        ['bem.enabled'] = true,
        ['bem.element'] = '__',
        ['bem.modifier'] = '--',
        
        -- Output options
        ['output.comment'] = false,
        ['output.field'] = function(index, placeholder)
          return placeholder
        end,
        ['output.format'] = true,
        ['output.formatLeafNode'] = false,
        ['output.formatSkip'] = { 'html' },
        ['output.formatForce'] = { 'body' },
        ['output.inlineBreak'] = 3,
        ['output.compactBoolean'] = false,
        ['output.booleanAttributes'] = {},
        ['output.reverseAttributes'] = false,
        ['output.selfClosingStyle'] = 'html', -- html, xml, xhtml
        
        -- Markup options
        ['markup.href'] = true,
        
        -- Comment options
        ['comment.enabled'] = false,
        ['comment.trigger'] = { 'id', 'class' },
        ['comment.before'] = '',
        ['comment.after'] = '\\n<!-- /[#ID][.CLASS] -->',
        
        -- Filter options
        ['filter.commentAfter'] = '\\n<!-- /[#ID][.CLASS] -->',
        ['filter.commentBefore'] = '',
        ['filter.commentTrigger'] = { 'id', 'class' },
      },
    },
    css = {
      options = {
        -- CSS specific options
        ['css.keywords'] = {},
        ['css.unitAliases'] = { e = 'em', p = '%', x = 'ex', r = 'rem' },
        ['css.intUnit'] = 'px',
        ['css.floatUnit'] = 'em',
        ['css.autoInsertVendorPrefixes'] = true,
        
        -- Output options
        ['output.field'] = function(index, placeholder)
          return '${' .. index .. (placeholder and ':' .. placeholder or '') .. '}'
        end,
        ['output.between'] = ': ',
        ['output.after'] = ';',
      },
    },
    jsx = {
      options = {
        ['markup.attributes'] = {
          ['class*'] = 'className',
          ['for'] = 'htmlFor',
        },
        ['markup.valuePrefix'] = { 
          class = 'className=',
        },
      },
    },
  },
  settings = {},
}
