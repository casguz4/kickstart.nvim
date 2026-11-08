local h = ...

-- nvim-dap loads on its keys. Load it the way a key press would, so its
-- adapters, configurations and real maps are in place.
local function dap()
  require('lazy').load { plugins = { 'nvim-dap' } }
  return require 'dap'
end

local function mason_bin(name)
  local path = vim.fn.exepath(name)
  return path ~= '' and path:find('/mason/bin/', 1, true) and path or nil
end

h.test('debug: exactly one spec configures nvim-dap', function()
  local fragments = require('lazy.core.config').spec.meta.fragments
  local configs = 0
  for _, id in ipairs(h.plugin('nvim-dap')._.frags) do
    if fragments:get(id).spec.config then
      configs = configs + 1
    end
  end
  h.eq(configs, 1, 'nvim-dap specs with a config')
end)

for _, name in ipairs { 'pwa-node', 'pwa-chrome' } do
  h.test('debug: ' .. name .. ' runs the Mason js-debug-adapter as a server', function()
    if not mason_bin 'js-debug-adapter' then
      h.skip 'js-debug-adapter is not installed (:MasonInstall js-debug-adapter)'
    end
    local adapter = dap().adapters[name]
    h.ok(type(adapter) == 'table', name .. ' adapter is missing: ' .. vim.inspect(adapter))
    h.eq(adapter.type, 'server', name .. ' adapter type')
    h.eq(adapter.port, '${port}', name .. ' adapter port')
    h.ok(adapter.executable, name .. ' adapter has no executable')
    h.ok(mason_bin(adapter.executable.command), name .. ' adapter command is not a Mason shim: ' .. tostring(adapter.executable.command))
    h.eq(adapter.executable.args, { '${port}' }, name .. ' adapter args')
  end)
end

h.test('debug: Go debugs through nvim-dap-go with Mason delve', function()
  if not mason_bin 'dlv' then
    h.skip 'dlv is not installed (:MasonInstall delve)'
  end
  local d = dap()
  h.ok(d.adapters.go, 'go adapter is missing')
  h.ok(d.configurations.go and #d.configurations.go > 0, 'no go configurations')
end)

local js_configs = {
  { type = 'pwa-node', request = 'launch', name = 'Launch file' },
  { type = 'pwa-node', request = 'attach', name = 'Attach' },
  { type = 'pwa-chrome', request = 'launch', name = 'Start Chrome with "localhost"' },
}

for _, ft in ipairs { 'javascript', 'typescript', 'javascriptreact', 'typescriptreact' } do
  h.test('debug: ' .. ft .. ' has the three JS configurations', function()
    local configs = dap().configurations[ft]
    h.ok(configs, 'no configurations for ' .. ft)
    local got = vim.tbl_map(function(c)
      return { type = c.type, request = c.request, name = c.name }
    end, configs)
    h.eq(got, js_configs, ft .. ' configurations')
    for _, c in ipairs(configs) do
      h.ok(c.protocol == nil, c.name .. ' still sets protocol')
      h.ok(c.userDataDir == nil, c.name .. ' still sets userDataDir')
    end
    h.eq(configs[3].url, 'http://localhost:3000', 'Chrome url')
    h.eq(configs[2].processId, require('dap.utils').pick_process, 'Attach processId')
  end)
end

h.test('debug: dap-ui opens on session start and closes on its end', function()
  local listeners = dap().listeners
  h.ok(listeners.after.event_initialized['dapui_config'], 'no dap-ui open listener')
  h.ok(listeners.before.event_terminated['dapui_config'], 'no dap-ui close listener (terminated)')
  h.ok(listeners.before.event_exited['dapui_config'], 'no dap-ui close listener (exited)')
end)

local keys = {
  { lhs = '<leader>db', desc = 'Debug: Toggle [B]reakpoint' },
  { lhs = '<leader>dB', desc = 'Debug: Conditional [B]reakpoint' },
  { lhs = '<F5>', desc = 'Debug: Start/Continue' },
  { lhs = '<F1>', desc = 'Debug: Step Into' },
  { lhs = '<F2>', desc = 'Debug: Step Over' },
  { lhs = '<F3>', desc = 'Debug: Step Out' },
  { lhs = '<F7>', desc = 'Debug: See last session result.' },
}

for _, case in ipairs(keys) do
  local lhs, desc = case.lhs, case.desc
  h.test('debug: ' .. lhs .. ' resolves to "' .. desc .. '"', function()
    local m = h.map('n', lhs)
    h.ok(m, lhs .. ' is not mapped')
    h.eq(m.desc, desc, lhs .. ' desc')
  end)
end

h.test('debug: <leader>db toggles a breakpoint on the cursor line', function()
  -- A scratch file, not a fixture: reopening a fixture buffer later in
  -- another window would miss its per-window fold setup.
  local path = vim.fn.tempname() .. '.txt'
  vim.fn.writefile({ 'one', 'two' }, path)
  local buf = h.open(path)
  dap()
  local breakpoints = require 'dap.breakpoints'
  breakpoints.clear()
  local function count()
    return #(breakpoints.get(buf)[buf] or {})
  end
  vim.api.nvim_feedkeys(vim.keycode '<leader>db', 'mx', false)
  h.eq(count(), 1, 'breakpoints after one <leader>db')
  vim.api.nvim_feedkeys(vim.keycode '<leader>db', 'mx', false)
  h.eq(count(), 0, 'breakpoints after a second <leader>db')
end)

for _, lhs in ipairs { '<leader>b', '<leader>B' } do
  h.test('debug: ' .. lhs .. ' is no longer a direct map', function()
    dap()
    local m = h.map('n', lhs)
    h.ok(not m, lhs .. ' is still mapped: ' .. tostring(m and (m.desc or m.rhs)))
  end)
end
