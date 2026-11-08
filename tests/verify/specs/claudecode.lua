local h = ...

-- The keys only resolve; nothing here presses them, so no Claude Code
-- terminal (or its MCP server) starts during the run.
local keys = {
  { mode = 'n', lhs = '<leader>cc', desc = 'Toggle [C]laude [C]ode' },
  { mode = 'n', lhs = '<leader>af', desc = 'Focus Claude' },
  { mode = 'n', lhs = '<leader>ar', desc = 'Resume Claude' },
  { mode = 'n', lhs = '<leader>aC', desc = 'Continue Claude' },
  { mode = 'n', lhs = '<leader>am', desc = 'Select Claude model' },
  { mode = 'n', lhs = '<leader>ab', desc = 'Add current buffer' },
  { mode = 'x', lhs = '<leader>as', desc = 'Send to Claude' },
  { mode = 'n', lhs = '<leader>aa', desc = 'Accept diff' },
  { mode = 'n', lhs = '<leader>ad', desc = 'Deny diff' },
}

for _, case in ipairs(keys) do
  local mode, lhs, desc = case.mode, case.lhs, case.desc
  h.test('claudecode: ' .. mode .. ' ' .. lhs .. ' resolves to "' .. desc .. '"', function()
    local m = h.map(mode, lhs)
    h.ok(m, lhs .. ' is not mapped in mode ' .. mode)
    h.eq(m.desc, desc, lhs .. ' desc')
  end)
end

h.test('claudecode: :ClaudeCode exists for <leader>cc to run', function()
  h.eq(vim.fn.exists ':ClaudeCode', 2, ':ClaudeCode command')
end)

for _, mode in ipairs { 'n', 'x' } do
  h.test('claudecode: which-key shows <leader>a as a group in mode ' .. mode, function()
    local wk_mode = require('which-key.buf').get { mode = mode }
    h.ok(wk_mode, 'which-key has no ' .. mode .. ' mode for the current buffer')
    local node = wk_mode.tree:find '<leader>a'
    h.ok(node and node.mapping and node.mapping.group, '<leader>a is not a which-key group in mode ' .. mode)
    h.ok(node.mapping.desc and node.mapping.desc ~= '', '<leader>a group has no label')
  end)
end
