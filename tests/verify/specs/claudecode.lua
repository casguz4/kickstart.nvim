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
    h.expect_map(mode, lhs, desc)
  end)
end

-- The commands those keys run, there before any key has loaded the plugin.
for _, cmd in ipairs { 'ClaudeCode', 'ClaudeCodeFocus', 'ClaudeCodeSelectModel', 'ClaudeCodeAdd', 'ClaudeCodeSend', 'ClaudeCodeDiffAccept', 'ClaudeCodeDiffDeny' } do
  h.test('claudecode: :' .. cmd .. ' exists for its key to run', function()
    h.eq(vim.fn.exists(':' .. cmd), 2, ':' .. cmd .. ' command')
  end)
end

for _, mode in ipairs { 'n', 'x' } do
  h.test('claudecode: which-key shows <leader>a as a group in mode ' .. mode, function()
    h.eq(h.key_group('<leader>a', mode), '[A]I (Claude Code)', '<leader>a group in mode ' .. mode)
  end)
end
