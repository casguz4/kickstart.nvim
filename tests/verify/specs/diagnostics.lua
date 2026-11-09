local h = ...

h.test('diagnostics: its plugins are installed and the ones it replaced are removed', function()
  h.expect_plugins {
    installed = { 'SchemaStore.nvim' },
    removed = { 'nvim-lint' },
  }
end)

-- Diagnostics come only from language servers. SchemaStore.nvim gives jsonls
-- and yamlls a schema for each file by name; both fixtures below are matched by
-- name and carry a top-level key their schema forbids. The servers download
-- the schema, so these tests need the network.
--
-- jsonls has no schema catalog of its own, so the JSON case is what proves
-- SchemaStore.nvim is wired in. yamlls's built-in store would also match the
-- compose file; that case guards YAML schema validation itself. yamlls matches
-- no schema for a file under a dot-directory (this checkout is usually in
-- `~/.config`), so the YAML fixture is opened from a temp copy.
local DIAGNOSTIC_TIMEOUT_MS = 20000
local BAD_KEY = 'notARealOption'

local cases = {
  { file = 'data/vercel.json', server = 'jsonls', schema = 'vercel.json' },
  { file = 'data/compose.yaml', server = 'yamlls', schema = 'compose spec', copy = true },
}

for _, case in ipairs(cases) do
  h.test(string.format('diagnostics: %s flags a key its %s schema forbids', case.server, case.schema), function()
    local file = case.copy and h.copy_fixture(case.file) or case.file
    h.expect_servers(file, { includes = { case.server } })
    local buf = vim.api.nvim_get_current_buf()
    local line = h.position_of(buf, BAD_KEY).line

    local flagged = vim.wait(DIAGNOSTIC_TIMEOUT_MS, function()
      return #vim.diagnostic.get(buf, { lnum = line }) > 0
    end, 100)

    local all = vim.tbl_map(function(d)
      return string.format('%d: %s', d.lnum + 1, d.message)
    end, vim.diagnostic.get(buf))
    h.ok(flagged, string.format('no diagnostic on `%s` (line %d); diagnostics: %s', BAD_KEY, line + 1, vim.inspect(all)))
  end)
end
