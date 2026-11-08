-- Entry point, loaded via -c by tests/verify.sh. Loads every spec in
-- tests/verify/specs (alphabetically), runs them, prints a report and exits
-- non-zero when any test fails.
local h = dofile(vim.env.VERIFY_REPO .. '/tests/verify/harness.lua')

local function out(line)
  io.stdout:write(line .. '\n')
end

-- Ends a run stuck waiting (a server that never answers). Fires only while the
-- event loop turns, e.g. inside vim.wait; a hard synchronous block still hangs.
local TIMEOUT_MS = 180000
vim.defer_fn(function()
  out(string.format('TIMEOUT: harness did not finish within %ds', TIMEOUT_MS / 1000))
  vim.cmd 'cquit 2'
end, TIMEOUT_MS)

local function boot()
  -- Headless Nvim never fires UIEnter, so lazy.nvim never fires VeryLazy.
  -- Stand in for the UI attaching so VeryLazy plugins load as they would for a user.
  if not vim.g.did_very_lazy then
    vim.api.nvim_exec_autocmds('UIEnter', { modeline = false })
    vim.wait(5000, function()
      return vim.g.did_very_lazy
    end)
  end

  h._snapshot_startup()
end

local function run()
  boot()

  local specs = vim.fn.globpath(h.repo .. '/tests/verify/specs', '*.lua', false, true)
  table.sort(specs)
  for _, file in ipairs(specs) do
    local chunk = assert(loadfile(file))
    chunk(h)
  end

  local filter = vim.env.VERIFY_FILTER or ''
  local counts = { pass = 0, fail = 0, skip = 0 }
  local failures = {}

  for _, t in ipairs(h._tests()) do
    if filter == '' or t.name:find(filter, 1, true) then
      local ok, err = pcall(t.fn)
      h._cleanup()
      if ok then
        counts.pass = counts.pass + 1
        out('  ok    ' .. t.name)
      elseif h._is_skip(err) then
        counts.skip = counts.skip + 1
        out('  skip  ' .. t.name .. ' -- ' .. err.reason)
      else
        counts.fail = counts.fail + 1
        local msg = type(err) == 'string' and err or vim.inspect(err)
        table.insert(failures, { name = t.name, msg = msg })
        out('  FAIL  ' .. t.name)
      end
    end
  end

  if #failures > 0 then
    out '\nFailures:'
    for _, f in ipairs(failures) do
      out('\n  ' .. f.name .. '\n    ' .. f.msg:gsub('\n', '\n    '))
    end
  end
  out(string.format('\n%d passed, %d failed, %d skipped', counts.pass, counts.fail, counts.skip))

  if counts.pass + counts.fail + counts.skip == 0 then
    out(string.format("No tests matched '%s'", filter))
    vim.cmd 'cquit 1'
  end
  vim.cmd(counts.fail > 0 and 'cquit 1' or 'qall!')
end

vim.schedule(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    out('HARNESS ERROR: ' .. tostring(err))
    vim.cmd 'cquit 3'
  end
end)
