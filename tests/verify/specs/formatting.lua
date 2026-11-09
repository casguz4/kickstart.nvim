local h = ...

h.test('formatting: its plugins are installed', function()
  h.expect_plugins {
    installed = { 'conform.nvim' },
  }
end)

-- Formatting is Prettier's (through conform) and stylua's, so none of these
-- servers may offer to format: conform's `lsp_format = 'prefer'` would pick
-- them over Prettier. `supports_method` also sees capabilities a server
-- registers after it starts.
local cases = {
  { file = 'src/index.ts', server = 'tsc' },
  { file = 'src/index.ts', server = 'eslint' },
  { file = 'src/App.vue', server = 'vtsls' },
  { file = 'src/App.vue', server = 'vue_ls' },
  { file = 'src/styles.css', server = 'cssls' },
  { file = 'src/index.html', server = 'html' },
  { file = 'data/settings.json', server = 'jsonls' },
  { file = 'data/settings.yaml', server = 'yamlls' },
  { file = 'notes.md', server = 'rumdl' },
  { file = 'lua/sample.lua', server = 'lua_ls' },
}

for _, case in ipairs(cases) do
  h.test(string.format('formatting: %s does not format %s', case.server, case.file:match '%.%w+$'), function()
    h.expect_servers(case.file, { includes = { case.server } })
    local buf = vim.api.nvim_get_current_buf()
    local client = vim.lsp.get_clients({ bufnr = buf, name = case.server })[1]
    local formats = vim.tbl_filter(function(method)
      return client:supports_method(method, buf)
    end, { 'textDocument/formatting', 'textDocument/rangeFormatting', 'textDocument/rangesFormatting' })
    h.eq(formats, {}, case.server .. ' formatting methods')
  end)
end
