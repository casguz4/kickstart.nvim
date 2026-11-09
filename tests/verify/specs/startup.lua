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

-- tests/verify.sh signs the run out of everything, so no server it starts
-- (Copilot, gh-backed tools) can log in or send text anywhere.
h.test('startup: no credential env vars reach Nvim', function()
  local leaked = {}
  for name in pairs(vim.fn.environ()) do
    local upper = name:upper()
    if
      upper:find('TOKEN', 1, true)
      or upper:find('SECRET', 1, true)
      or upper:find('API_KEY', 1, true)
      or upper:find '^GITHUB_'
      or upper:find '^GH_'
      or upper:find '^COPILOT_'
    then
      table.insert(leaked, name)
    end
  end
  table.sort(leaked)
  h.eq(leaked, {}, 'credential env vars visible to Nvim')
end)

h.test('startup: the config home has no login dirs', function()
  for _, dir in ipairs { 'github-copilot', 'gh' } do
    local path = vim.env.XDG_CONFIG_HOME .. '/' .. dir
    h.ok(vim.uv.fs_lstat(path) == nil, path .. ' is linked into the test config home')
  end
end)
