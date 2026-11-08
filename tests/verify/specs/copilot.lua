local h = ...

-- Copilot is off every session: no client, no server process, until
-- <leader>tc. These tests start the server only to see it attach and detach;
-- they never enter Insert mode, so no suggestion is ever requested.

local SETTLE_MS = 1500
local START_MS = 20000

-- The server these tests start is never signed in: it runs with an empty home
-- and config dirs and without the shell's GitHub/Copilot tokens, so it finds no
-- login and has nothing to send text to GitHub with.
local function signed_out_cmd()
  local home = vim.fn.tempname()
  for _, sub in ipairs { '.config', '.local/share', '.local/state', '.cache' } do
    vim.fn.mkdir(home .. '/' .. sub, 'p')
  end
  local cmd = { 'env' }
  for name in pairs(vim.fn.environ()) do
    local upper = name:upper()
    if upper:find('TOKEN', 1, true) or upper:find('GITHUB', 1, true) or upper:find('COPILOT', 1, true) or upper:find '^GH_' then
      vim.list_extend(cmd, { '-u', name })
    end
  end
  vim.list_extend(cmd, {
    'HOME=' .. home,
    'XDG_CONFIG_HOME=' .. home .. '/.config',
    'XDG_DATA_HOME=' .. home .. '/.local/share',
    'XDG_STATE_HOME=' .. home .. '/.local/state',
    'XDG_CACHE_HOME=' .. home .. '/.cache',
    'copilot-language-server',
    '--stdio',
  })
  return cmd
end
vim.lsp.config('copilot', { cmd = signed_out_cmd() })

-- Whatever <leader>tc does, done the way the key does it.
local function press_toggle()
  local m = h.map('n', '<leader>tc')
  h.ok(m and m.callback, '<leader>tc is not mapped to a function')
  m.callback()
end

local function copilot_clients(buf)
  return vim.lsp.get_clients { name = 'copilot', bufnr = buf }
end

local function skip_unless_installed()
  if vim.fn.executable 'copilot-language-server' == 0 then
    h.skip 'copilot-language-server is not installed (install it with :MasonInstall copilot-language-server)'
  end
end

-- Run `fn` with Copilot turned on by <leader>tc, and leave it off afterwards
-- even when `fn` fails, so later tests never see a copilot client.
local function with_copilot_on(fn)
  press_toggle()
  local ok, err = pcall(fn)
  if vim.lsp.is_enabled 'copilot' then
    press_toggle()
  end
  vim.wait(START_MS, function()
    return #copilot_clients() == 0
  end, 50)
  if not ok then
    error(err, 0)
  end
end

-- Runs first (specs load alphabetically): nothing else has toggled Copilot yet.
h.test('copilot: no client at startup, even with a file open', function()
  local buf = h.open 'src/index.ts'
  vim.wait(SETTLE_MS)
  h.ok(not vim.list_contains(h.servers(buf), 'copilot'), 'copilot is attached to src/index.ts at startup')
  h.eq(#copilot_clients(), 0, 'copilot clients at startup')
end)

h.test('copilot: <leader>tc attaches it to .ts, a second <leader>tc detaches it', function()
  skip_unless_installed()
  local buf = h.open 'src/index.ts'
  vim.wait(SETTLE_MS)
  h.eq(#copilot_clients(), 0, 'copilot clients before <leader>tc')

  with_copilot_on(function()
    local attached = vim.wait(START_MS, function()
      return #copilot_clients(buf) == 1
    end, 50)
    h.ok(attached, 'copilot did not attach to src/index.ts after <leader>tc (attached: ' .. table.concat(h.servers(buf), ', ') .. ')')

    press_toggle()
    local stopped = vim.wait(START_MS, function()
      return #copilot_clients() == 0
    end, 50)
    h.ok(stopped, 'copilot is still running after a second <leader>tc')
    h.ok(not vim.list_contains(h.servers(buf), 'copilot'), 'copilot is still attached to src/index.ts')
  end)
end)

-- Buffers Copilot must stay off in, even while it is on. Each is opened while
-- Copilot is off and checked once turning it on has attached it to a .ts
-- buffer, so the server is running and had the chance to attach.
local function excluded_buffers()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local function file(name, lines)
    vim.fn.writefile(lines, dir .. '/' .. name)
    return dir .. '/' .. name
  end
  return {
    {
      label = 'a gitcommit buffer',
      open = function()
        return h.open(file('COMMIT_EDITMSG', { 'Add a thing', '', '# Please enter the commit message' }))
      end,
      filetype = 'gitcommit',
    },
    {
      label = 'an empty-filetype buffer',
      open = function()
        return h.open(file('scratch', { 'just some words' }))
      end,
      filetype = '',
    },
    {
      label = 'a help buffer',
      open = function()
        vim.cmd 'help lsp'
        return vim.api.nvim_get_current_buf()
      end,
      buftype = 'help',
    },
  }
end

for _, case in ipairs(excluded_buffers()) do
  h.test('copilot: stays off in ' .. case.label .. ' while on', function()
    skip_unless_installed()
    local ts = h.open 'src/index.ts'
    local buf = case.open()
    if case.filetype then
      h.eq(vim.bo[buf].filetype, case.filetype, case.label .. ' filetype')
    end
    if case.buftype then
      h.eq(vim.bo[buf].buftype, case.buftype, case.label .. ' buftype')
    end

    with_copilot_on(function()
      local attached = vim.wait(START_MS, function()
        return #copilot_clients(ts) == 1
      end, 50)
      h.ok(attached, 'copilot did not attach to src/index.ts, so the check proves nothing')
      vim.wait(SETTLE_MS)
      h.eq(#copilot_clients(buf), 0, 'copilot clients on ' .. case.label)
    end)

    if case.buftype == 'help' then
      vim.cmd 'helpclose'
    end
  end)
end

-- Suggestions are ghost text; these keys accept and cycle them.
local insert_keys = {
  { lhs = '<C-J>', what = 'accept' },
  { lhs = '<M-]>', what = 'next' },
  { lhs = '<M-[>', what = 'previous' },
}

for _, key in ipairs(insert_keys) do
  h.test('copilot: ' .. key.lhs .. ' is the ' .. key.what .. '-suggestion key in Insert mode', function()
    local m = h.map('i', key.lhs)
    h.ok(m, key.lhs .. ' is not mapped in Insert mode')
    h.ok(m.desc and m.desc:find('Copilot', 1, true), key.lhs .. ' is not a Copilot key: ' .. vim.inspect(m.desc))
  end)
end

h.test('copilot: <leader>tc is the Copilot toggle', function()
  local m = h.map('n', '<leader>tc')
  h.ok(m, '<leader>tc is not mapped')
  -- which-key shows the desc; kickstart brackets the key letters ("[C]opilot").
  local desc = (m.desc or ''):gsub('[%[%]]', '')
  h.ok(desc:find('Copilot', 1, true), '<leader>tc desc does not name Copilot: ' .. vim.inspect(m.desc))
end)
