local h = ...

h.test('startup: runs on Neovim 0.12', function()
  local v = vim.version()
  h.eq({ v.major, v.minor }, { 0, 12 }, 'nvim version (major, minor)')
end)

h.test('startup: no errors in :messages or error notifications', function()
  local errs = h.startup_errors()
  h.ok(#errs == 0, 'startup reported errors:\n' .. table.concat(errs, '\n'))
end)

-- A deprecation comes from this config when its stack trace has a frame in the
-- config dir. The harness's own frames (tests/) are in every trace, so skip them.
local function from_config(problem)
  local config = vim.fn.stdpath 'config'
  for _, frame in ipairs(problem.detail) do
    local in_config = vim.startswith(frame, config .. '/') or vim.startswith(frame, h.repo .. '/')
    if in_config and not frame:find('/tests/', 1, true) then
      return true
    end
  end
  return false
end

h.test('startup: :checkhealth vim.deprecated has nothing from this config', function()
  -- Most deprecated calls sit on the LSP attach path; make sure it has run.
  h.expect_servers('lua/sample.lua', { includes = { 'lua_ls' } })
  local ours = vim.tbl_filter(from_config, h.checkhealth_problems 'vim.deprecated')
  h.ok(#ours == 0, 'deprecated calls from this config:\n' .. table.concat(
    vim.tbl_map(function(p)
      return p.text .. '\n  ' .. table.concat(p.detail, '\n  ')
    end, ours),
    '\n'
  ))
end)

-- Errors from any source, plugins included. For vim.deprecated this is the
-- broader net under the config-only check above.
for _, section in ipairs { 'vim.lsp', 'vim.deprecated' } do
  h.test('startup: :checkhealth ' .. section .. ' reports no errors', function()
    local errs = h.checkhealth_errors(section)
    h.ok(#errs == 0, table.concat(errs, '\n'))
  end)
end
