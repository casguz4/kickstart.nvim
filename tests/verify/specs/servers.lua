local h = ...

h.test('servers: its plugins are installed', function()
  h.expect_plugins {
    installed = { 'lazydev.nvim', 'mason-tool-installer.nvim', 'mason.nvim', 'nvim-lspconfig' },
  }
end)

-- Servers each fixture file gets. Baseline: only servers that attach on the
-- 0.11 config and stay attached after the migration. Migration tickets add the
-- servers they route in (`includes`) and the ones they route out (`excludes`).
local cases = {
  { file = 'lua/sample.lua', includes = { 'lua_ls', 'stylua' } },
  { file = 'src/index.ts', includes = { 'tsc', 'eslint' }, excludes = { 'ts_ls', 'tsgo', 'vtsls' } },
  { file = 'src/App.vue', includes = { 'vtsls', 'vue_ls' }, excludes = { 'tsc', 'stylelint_lsp' } },
  { file = 'src/styles.css', includes = { 'cssls', 'stylelint_lsp' } },
  -- stylelint_lsp lints only css/scss/less, so it stays off markup with <style>.
  { file = 'src/index.html', includes = { 'html' }, excludes = { 'stylelint_lsp' } },
  { file = 'src/Page.astro', includes = { 'astro' }, excludes = { 'stylelint_lsp' } },
  { file = 'data/settings.json', includes = { 'jsonls' } },
  { file = 'data/settings.yaml', includes = { 'yamlls' } },
  { file = 'notes.md', includes = { 'rumdl', 'marksman' } },
}

for _, case in ipairs(cases) do
  local ext = case.file:match '%.%w+$'
  local label = table.concat(case.includes, ' + ')
  if case.excludes and #case.excludes > 0 then
    label = label .. ', not ' .. table.concat(case.excludes, '/')
  end
  h.test(string.format('servers: %s attaches %s', ext, label), function()
    h.expect_servers(case.file, case)
  end)
end

-- eslint attaches only where it can lint: an ESLint config *and* ESLint
-- installed. A project with only the config gets no eslint server.
h.test('servers: .ts with an ESLint config but no installed eslint does not attach eslint', function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/src', 'p')
  vim.fn.writefile({ '{ "name": "no-eslint", "private": true }' }, dir .. '/package.json')
  vim.fn.writefile({ 'export default []' }, dir .. '/eslint.config.js')
  vim.fn.writefile({ 'export const n = 1' }, dir .. '/src/index.ts')
  h.expect_servers(dir .. '/src/index.ts', { includes = { 'tsc' }, excludes = { 'eslint' } })
end)
