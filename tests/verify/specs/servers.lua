local h = ...

-- Servers each fixture file gets. Baseline: only servers that attach on the
-- 0.11 config and stay attached after the migration. Migration tickets add the
-- servers they route in (`includes`) and the ones they route out (`excludes`).
local cases = {
  { file = 'lua/sample.lua', includes = { 'lua_ls' } },
  { file = 'src/index.ts', includes = { 'eslint' } },
  { file = 'src/styles.css', includes = { 'cssls' } },
  { file = 'data/settings.json', includes = { 'jsonls' } },
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
