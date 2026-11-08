-- Helpers for verification specs. Each spec file receives this table as `...`:
--
--   local h = ...
--   h.test('plugins: nvim-ufo is gone', function()
--     h.ok(not h.plugin 'nvim-ufo', 'nvim-ufo is still in the lazy registry')
--   end)
--
-- Assertions raise errors; the runner reports the test as failed with that
-- message. `h.skip(reason)` ends a test early as skipped.
local h = {}

h.repo = vim.env.VERIFY_REPO
h.fixture = h.repo .. '/tests/fixture'

local tests = {}
local SKIP = {}

---Register a test. Names should read as `<area>: <observable behavior>`.
---@param name string
---@param fn fun()
function h.test(name, fn)
  table.insert(tests, { name = name, fn = fn })
end

function h._tests()
  return tests
end

function h._is_skip(err)
  return getmetatable(err) == SKIP
end

---End the current test as skipped.
---@param reason string
function h.skip(reason)
  error(setmetatable({ reason = reason }, SKIP), 0)
end

---@param cond any
---@param msg string
function h.ok(cond, msg)
  if not cond then
    error(msg, 2)
  end
end

---@param actual any
---@param expected any
---@param what string what is being compared, e.g. "foldcolumn"
function h.eq(actual, expected, what)
  if not vim.deep_equal(actual, expected) then
    error(string.format('%s: expected %s, got %s', what, vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

-- [[ Startup ]]

local error_patterns = {
  '^E%d+:',
  'Error detected while processing',
  'Error executing',
  'stack traceback',
}

local function error_lines(text)
  local found = {}
  for line in vim.gsplit(text, '\n', { plain = true }) do
    for _, pat in ipairs(error_patterns) do
      if line:find(pat) then
        table.insert(found, line)
        break
      end
    end
  end
  return found
end

local startup_errors

---Snapshot startup errors. Called by the runner once the config has booted.
function h._snapshot_startup()
  startup_errors = error_lines(vim.fn.execute 'messages')
  vim.list_extend(startup_errors, _G.__verify_notify_errors or {})
end

---Error lines from :messages plus ERROR-level notifications, as of the moment
---the config finished booting (before any spec ran). Notifications sent through
---a plugin that replaces `vim.notify` after the prelude ran are not seen.
---@return string[]
function h.startup_errors()
  return startup_errors
end

---WARNING and ERROR items reported by `:checkhealth {section}`. Each item is
---its headline plus the indented lines under it (advice, stack traces).
---@param section string e.g. 'vim.deprecated'
---@return { level: 'WARNING'|'ERROR', text: string, detail: string[] }[]
function h.checkhealth_problems(section)
  local tab = vim.api.nvim_get_current_tabpage()
  vim.cmd('silent checkhealth ' .. section)
  h.ok(vim.api.nvim_get_current_tabpage() ~= tab, ':checkhealth ' .. section .. ' did not open a report tab')
  local buf = vim.api.nvim_get_current_buf()
  vim.wait(10000, function()
    return vim.api.nvim_buf_line_count(buf) > 1
  end)
  -- Items read `- ⚠️ WARNING msg` / `- ❌ ERROR msg`; their detail is every
  -- following line indented deeper than the item.
  local found, item, item_indent = {}, nil, 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local indent, level = line:match '^(%s*)%-%s+[^%a]*(%u+)'
    if level == 'WARNING' or level == 'ERROR' then
      item, item_indent = { level = level, text = vim.trim(line), detail = {} }, #indent
      table.insert(found, item)
    elseif item and #line:match '^%s*' > item_indent and line:find '%S' then
      table.insert(item.detail, vim.trim(line))
    else
      item = nil
    end
  end
  vim.cmd 'tabclose'
  return found
end

---ERROR lines reported by `:checkhealth {section}`.
---@param section string e.g. 'vim.lsp'
---@return string[]
function h.checkhealth_errors(section)
  local errors = vim.tbl_filter(function(p)
    return p.level == 'ERROR'
  end, h.checkhealth_problems(section))
  return vim.tbl_map(function(p)
    return p.text
  end, errors)
end

-- [[ Plugins ]]

---The plugin's entry in lazy.nvim's registry (loaded or not), or nil when no
---spec declares it.
---@param name string plugin name as lazy shows it, e.g. 'nvim-ufo'
---@return table?
function h.plugin(name)
  return require('lazy.core.config').plugins[name]
end

-- [[ Buffers & language servers ]]

local ATTACH_TIMEOUT_MS = 20000
-- After the expected servers attach, how long to keep watching for ones that
-- shouldn't.
local SETTLE_MS = 1500

-- A fixture path relative to tests/fixture, or an absolute path as is.
local function fixture_path(rel)
  return rel:sub(1, 1) == '/' and rel or h.fixture .. '/' .. rel
end

---Edit a fixture file in the current window.
---@param rel string path relative to tests/fixture, e.g. 'src/index.ts', or an absolute path
---@return integer bufnr
function h.open(rel)
  vim.cmd.edit(vim.fn.fnameescape(fixture_path(rel)))
  return vim.api.nvim_get_current_buf()
end

---Copy a fixture file, keeping its name, into a fresh temp dir with no
---dot-directory in its path, and return the copy's absolute path. For servers
---that never match a file under one (yamlls's schema globs skip any path with a
---`.dir` in it, and this checkout usually lives in `~/.config`).
---@param rel string path relative to tests/fixture
---@return string path
function h.copy_fixture(rel)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local path = dir .. '/' .. vim.fs.basename(rel)
  vim.fn.writefile(vim.fn.readfile(fixture_path(rel), 'b'), path, 'b')
  assert(not path:find '/%.', 'temp dir has a dot-directory in its path: ' .. path)
  return path
end

local sibling_copies = {}

---Copy a fixture file next to itself as `<name>.saved.<ext>` and return the
---copy's absolute path. The copy stays in the fixture project, so its configs,
---servers and `node_modules` apply: saving it runs the real save pipeline
---without touching the original. Deleted (buffer and file) when the test ends;
---gitignored in case a run is cut short.
---@param rel string path relative to tests/fixture
---@return string path
function h.sibling_copy(rel)
  local src = fixture_path(rel)
  local path = src:gsub('(%.%w+)$', '.saved%1')
  vim.fn.writefile(vim.fn.readfile(src, 'b'), path, 'b')
  table.insert(sibling_copies, path)
  return path
end

---Delete the test's `h.sibling_copy` files. Called by the runner after each test.
function h._cleanup()
  for _, path in ipairs(sibling_copies) do
    local buf = vim.fn.bufnr(path)
    if buf ~= -1 then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.fn.delete(path)
  end
  sibling_copies = {}
end

---The lines of a file under tests/verify/expected.
---@param name string e.g. 'messy.ts'
---@return string[]
function h.expected(name)
  return vim.fn.readfile(h.repo .. '/tests/verify/expected/' .. name)
end

---Names of the language servers attached to a buffer, sorted.
---@param buf integer
---@return string[]
function h.servers(buf)
  local names = vim.tbl_map(function(c)
    return c.name
  end, vim.lsp.get_clients { bufnr = buf })
  table.sort(names)
  return names
end

-- The executable a server config launches, when it names one up front. A
-- config whose `cmd` is a function gives nothing to check, so it never skips.
local function server_bin(name)
  local cfg = vim.lsp.config[name]
  local cmd = cfg and cfg.cmd
  if type(cmd) == 'table' then
    return cmd[1]
  end
end

-- The `names` not in `attached`.
local function not_in(names, attached)
  return vim.tbl_filter(function(name)
    return not vim.list_contains(attached, name)
  end, names)
end

---Open a fixture file and assert which language servers attach to it. Skips
---when an `includes` server's executable isn't installed (Mason's bin dir is
---on PATH), so a missing install doesn't read as a config failure.
---@param rel string path relative to tests/fixture, or an absolute path
---@param want { includes?: string[], excludes?: string[] }
function h.expect_servers(rel, want)
  local includes, excludes = want.includes or {}, want.excludes or {}

  for _, name in ipairs(includes) do
    local bin = server_bin(name)
    if bin and vim.fn.executable(bin) == 0 then
      h.skip(string.format("%s is not installed ('%s' not on PATH; install it with :MasonInstall)", name, bin))
    end
  end

  local buf = h.open(rel)
  vim.wait(ATTACH_TIMEOUT_MS, function()
    return #not_in(includes, h.servers(buf)) == 0
  end, 50)
  vim.wait(SETTLE_MS)

  local attached = h.servers(buf)
  local missing, unexpected = not_in(includes, attached), {}
  for _, name in ipairs(excludes) do
    if vim.list_contains(attached, name) then
      table.insert(unexpected, name)
    end
  end

  if #missing > 0 or #unexpected > 0 then
    local parts = {}
    if #missing > 0 then
      table.insert(parts, 'not attached: ' .. table.concat(missing, ', '))
    end
    if #unexpected > 0 then
      table.insert(parts, 'should not attach: ' .. table.concat(unexpected, ', '))
    end
    error(string.format('%s: %s (attached: %s)', rel, table.concat(parts, '; '), table.concat(attached, ', ')), 2)
  end
end

-- [[ Requests ]]

-- Servers answer empty while they load the project; how long to keep re-asking,
-- and how long each single request may take.
local REQUEST_UNTIL_MS = 20000
local REQUEST_MS = 5000
local RETRY_MS = 500

---The first position of `text` in `buf`, as an LSP position (0-based).
---@param buf integer
---@param text string plain text, not a pattern
---@return lsp.Position
function h.position_of(buf, text)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local col = line:find(text, 1, true)
    if col then
      return { line = i - 1, character = col - 1 }
    end
  end
  error(string.format('`%s` not found in buffer %d', text, buf), 2)
end

-- Hover `contents` as text. vtsls sends a bare MarkedString; most servers send
-- MarkupContent; the spec also allows a MarkedString list.
local function hover_text(contents)
  if type(contents) == 'string' then
    return contents
  end
  if contents.value then
    return contents.value
  end
  return table.concat(
    vim.tbl_map(function(c)
      return type(c) == 'string' and c or c.value
    end, contents),
    '\n'
  )
end

---Ask the `server` client attached to `buf` for hover text at `pos`, re-asking
---until `done(text)` returns true or the budget runs out. Sends one request at
---a time: requesting from inside a vim.wait predicate floods a server that
---answers instantly, and the wait never returns.
---@param buf integer
---@param server string client name, e.g. 'vtsls'
---@param pos lsp.Position
---@param done fun(text: string): boolean
---@return boolean ok, string text the last hover text ('' when empty)
function h.hover_until(buf, server, pos, done)
  local client = vim.lsp.get_clients({ bufnr = buf, name = server })[1]
  assert(client, server .. ' is not attached to buffer ' .. buf)
  local params = { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = pos }

  local text, deadline = '', vim.uv.now() + REQUEST_UNTIL_MS
  repeat
    local answered = false
    client:request('textDocument/hover', params, function(_, result)
      text = result and result.contents and hover_text(result.contents) or ''
      answered = true
    end, buf)
    vim.wait(REQUEST_MS, function()
      return answered
    end, 50)
    if done(text) then
      return true, text
    end
    vim.wait(RETRY_MS)
  until vim.uv.now() > deadline
  return false, text
end

-- [[ Keymaps & options ]]

---The mapping that answers `lhs` in `mode`, as `maparg(..., true)` describes it
---(`rhs`, `callback`, `desc`, `buffer`, ...), or nil when nothing is mapped.
---Pass `buf` to resolve from that buffer, so buffer-local maps count.
---@param mode string e.g. 'n'
---@param lhs string e.g. '<leader>e'
---@param buf? integer
---@return table?
function h.map(mode, lhs, buf)
  local m = vim.api.nvim_buf_call(buf or 0, function()
    return vim.fn.maparg(lhs, mode, false, true)
  end)
  return not vim.tbl_isempty(m) and m or nil
end

---An option's value. Without `buf`, the global value (what the config set and
---new windows/buffers start from). With `buf`, the value in effect there
---(window-local options are read from a window showing it).
---@param name string
---@param buf? integer
---@return any
function h.opt(name, buf)
  if not buf then
    return vim.api.nvim_get_option_value(name, { scope = 'global' })
  end
  local scope = vim.api.nvim_get_option_info2(name, {}).scope
  if scope == 'win' then
    local win = vim.fn.bufwinid(buf)
    assert(win ~= -1, 'buffer ' .. buf .. ' is not shown in any window')
    return vim.api.nvim_get_option_value(name, { win = win })
  end
  return vim.api.nvim_get_option_value(name, { buf = buf })
end

return h
