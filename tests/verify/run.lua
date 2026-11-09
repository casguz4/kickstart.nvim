-- Entry point, loaded via -c by tests/verify.sh. Loads every spec in
-- tests/verify/specs (alphabetically), runs them, prints a report and exits
-- non-zero when any test fails.
local h = dofile(vim.env.VERIFY_REPO .. '/tests/verify/harness.lua')

local function out(line)
  io.stdout:write(line .. '\n')
end

-- A full run (no filter) fails past this many seconds, so a slowdown is caught
-- when it lands instead of when a run hits TIMEOUT_MS. VERIFY_BUDGET_S overrides.
local BUDGET_S = tonumber(vim.env.VERIFY_BUDGET_S) or 60
local SLOWEST = 3

-- Set by prelude.lua before the config loads, so the run's time includes boot.
local run_start = _G.__verify_start or vim.uv.hrtime()

local function seconds_since(start_ns)
  return (vim.uv.hrtime() - start_ns) / 1e9
end

-- Each finished test's { name, seconds }, for the slowest-tests report.
local timings = {}

local function report_slowest()
  table.sort(timings, function(a, b)
    return a.seconds > b.seconds
  end)
  if #timings > 0 then
    out '\nSlowest:'
    for i = 1, math.min(SLOWEST, #timings) do
      out(string.format('  %5.1fs  %s', timings[i].seconds, timings[i].name))
    end
  end
end

-- Ends a run stuck waiting (a server that never answers). Fires only while the
-- event loop turns, e.g. inside vim.wait; a hard synchronous block still hangs.
local TIMEOUT_MS = 180000
vim.defer_fn(function()
  out(string.format('TIMEOUT: harness did not finish within %ds', TIMEOUT_MS / 1000))
  report_slowest()
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
  -- A spec file is one area: every test in specs/<area>.lua is named
  -- `<area>: ...`, so `verify.sh <area>:` runs exactly that file.
  local misnamed = {}
  for _, file in ipairs(specs) do
    local chunk = assert(loadfile(file))
    local before = #h._tests()
    chunk(h)
    local area = vim.fn.fnamemodify(file, ':t:r')
    for i = before + 1, #h._tests() do
      local name = h._tests()[i].name
      if name:sub(1, #area + 2) ~= area .. ': ' then
        table.insert(misnamed, string.format("specs/%s.lua: '%s' must start with '%s: '", area, name, area))
      end
    end
  end

  local filter = vim.env.VERIFY_FILTER or ''
  local counts = { pass = 0, fail = 0, skip = 0 }
  local failures = {}
  -- A check on the run itself rather than on the config.
  local function harness_fail(name, msg)
    counts.fail = counts.fail + 1
    table.insert(failures, { name = 'harness: ' .. name, msg = msg })
    out('  FAIL  harness: ' .. name)
  end

  for _, msg in ipairs(misnamed) do
    harness_fail('test names match their spec file', msg)
  end

  for _, t in ipairs(h._tests()) do
    if filter == '' or t.name:find(filter, 1, true) then
      local started = vim.uv.hrtime()
      local ok, err = pcall(t.fn)
      h._cleanup()
      table.insert(timings, { name = t.name, seconds = seconds_since(started) })
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

  local elapsed = seconds_since(run_start)
  if filter == '' and elapsed > BUDGET_S then
    harness_fail(
      'a full run finishes within the time budget',
      string.format('took %.1fs, budget is %ds (VERIFY_BUDGET_S); the slowest tests are listed below', elapsed, BUDGET_S)
    )
  end

  if #failures > 0 then
    out '\nFailures:'
    for _, f in ipairs(failures) do
      out('\n  ' .. f.name .. '\n    ' .. f.msg:gsub('\n', '\n    '))
    end
  end

  report_slowest()
  out(string.format('\n%d passed, %d failed, %d skipped in %.1fs', counts.pass, counts.fail, counts.skip, elapsed))

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
