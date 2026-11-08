local h = ...

h.test('startup: no errors in :messages or error notifications', function()
  local errs = h.startup_errors()
  h.ok(#errs == 0, 'startup reported errors:\n' .. table.concat(errs, '\n'))
end)

for _, section in ipairs { 'vim.lsp', 'vim.deprecated' } do
  h.test('startup: :checkhealth ' .. section .. ' reports no errors', function()
    local errs = h.checkhealth_errors(section)
    h.ok(#errs == 0, table.concat(errs, '\n'))
  end)
end
