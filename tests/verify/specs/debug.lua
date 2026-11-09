local h = ...

h.test('debug: its plugins are installed and the ones it replaced are removed', function()
  h.expect_plugins {
    installed = { 'nvim-dap', 'nvim-dap-go', 'nvim-dap-ui', 'nvim-nio' },
    removed = { 'mason-nvim-dap.nvim' },
  }
end)

-- nvim-dap loads on its keys. Load it the way a key press would, so its
-- adapters, configurations and real maps are in place.
local function load_dap()
  require('lazy').load { plugins = { 'nvim-dap' } }
  return require 'dap'
end

-- How long a debug session may take to start, and then to end.
local SESSION_MS = 15000

local function mason_bin(name)
  local path = vim.fn.exepath(name)
  return path ~= '' and path:find('/mason/bin/', 1, true) and path or nil
end

-- Every adapter and configuration dap has once loaded, by name. A second spec
-- configuring nvim-dap would replace this config (lazy.nvim runs one `config`)
-- or add its own adapters, and either changes these lists.
h.test('debug: loaded, dap has only the JS and Go adapters and configurations', function()
  local d = load_dap()
  local adapters, filetypes = vim.tbl_keys(d.adapters), vim.tbl_keys(d.configurations)
  table.sort(adapters)
  table.sort(filetypes)
  h.eq(adapters, { 'go', 'pwa-chrome', 'pwa-node' }, 'dap adapters')
  h.eq(filetypes, { 'go', 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }, 'filetypes with configurations')
end)

local function dapui_windows()
  return vim.tbl_filter(function(win)
    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype:find '^dapui_' ~= nil
  end, vim.api.nvim_list_wins())
end

-- A real session: "Launch file" on a script that exits by itself. It starts
-- only if pwa-node launches the Mason js-debug-adapter as a server on the port
-- dap picks, and dap-ui shows only while the session runs.
h.test('debug: Launch file debugs a .js file through js-debug, with dap-ui open while it runs', function()
  if not mason_bin 'js-debug-adapter' then
    h.skip 'js-debug-adapter is not installed (:MasonInstall js-debug-adapter)'
  end
  local d = load_dap()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local path = dir .. '/main.js'
  vim.fn.writefile({ 'setTimeout(() => {}, 300)' }, path)
  h.open(path)

  local launch = vim.iter(d.configurations.javascript):find(function(c)
    return c.name == 'Launch file'
  end)
  h.ok(launch, 'no "Launch file" configuration for javascript')
  d.run(launch)
  local opened = vim.wait(SESSION_MS, function()
    return #dapui_windows() > 0
  end, 50)
  h.ok(opened, 'dap-ui did not open after dap.run (session still running: ' .. tostring(d.session() ~= nil) .. ')')
  local ended = vim.wait(SESSION_MS, function()
    return d.session() == nil and #dapui_windows() == 0
  end, 50)
  if not ended then
    d.terminate()
  end
  h.ok(d.session() == nil, 'the session did not end when the script exited')
  h.eq(#dapui_windows(), 0, 'dap-ui windows once the session ended')
end)

-- Chrome isn't launched here; pwa-chrome must start the same js-debug server.
h.test('debug: pwa-chrome starts the Mason js-debug-adapter server, as pwa-node does', function()
  if not mason_bin 'js-debug-adapter' then
    h.skip 'js-debug-adapter is not installed (:MasonInstall js-debug-adapter)'
  end
  local adapters = load_dap().adapters
  local chrome, node = adapters['pwa-chrome'], adapters['pwa-node']
  h.ok(type(chrome) == 'table' and chrome.executable, 'pwa-chrome starts no executable: ' .. vim.inspect(chrome))
  h.eq(chrome.type, 'server', 'pwa-chrome adapter type')
  h.ok(mason_bin(chrome.executable.command), 'pwa-chrome command is not a Mason shim: ' .. tostring(chrome.executable.command))
  h.eq(chrome.executable, node.executable, 'pwa-chrome executable (pwa-node is started for real above)')
end)

h.test('debug: Go debugs through nvim-dap-go with Mason delve', function()
  if not mason_bin 'dlv' then
    h.skip 'dlv is not installed (:MasonInstall delve)'
  end
  local d = load_dap()
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
    local configs = load_dap().configurations[ft]
    h.ok(configs, 'no configurations for ' .. ft)
    local got = vim.tbl_map(function(c)
      return { type = c.type, request = c.request, name = c.name }
    end, configs)
    h.eq(got, js_configs, ft .. ' configurations')
    h.eq(configs[3].url, 'http://localhost:3000', 'Chrome url')
    h.eq(configs[2].processId, require('dap.utils').pick_process, 'Attach processId')
  end)
end

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
    h.expect_map('n', lhs, desc)
  end)
end

h.test('debug: <leader>db toggles a breakpoint on the cursor line', function()
  -- A scratch file, not a fixture: reopening a fixture buffer later in
  -- another window would miss its per-window fold setup.
  local path = vim.fn.tempname() .. '.txt'
  vim.fn.writefile({ 'one', 'two' }, path)
  local buf = h.open(path)
  load_dap()
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
    load_dap()
    local m = h.map('n', lhs)
    h.ok(not m, lhs .. ' is still mapped: ' .. tostring(m and (m.desc or m.rhs)))
  end)
end
