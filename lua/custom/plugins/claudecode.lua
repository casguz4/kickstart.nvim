-- Claude Code in a native terminal split, signed in with the CLI's own login.
return {
  'coder/claudecode.nvim',
  opts = {
    terminal = { provider = 'native' },
  },
  -- Command stubs for what the keys run, so they work before any key has
  -- loaded the plugin. Loading it defines the rest of `:ClaudeCode*`.
  cmd = {
    'ClaudeCode',
    'ClaudeCodeFocus',
    'ClaudeCodeSelectModel',
    'ClaudeCodeAdd',
    'ClaudeCodeSend',
    'ClaudeCodeDiffAccept',
    'ClaudeCodeDiffDeny',
  },
  keys = {
    { '<leader>cc', '<cmd>ClaudeCode<CR>', desc = 'Toggle [C]laude [C]ode' },
    { '<leader>af', '<cmd>ClaudeCodeFocus<CR>', desc = 'Focus Claude' },
    { '<leader>ar', '<cmd>ClaudeCode --resume<CR>', desc = 'Resume Claude' },
    { '<leader>aC', '<cmd>ClaudeCode --continue<CR>', desc = 'Continue Claude' },
    { '<leader>am', '<cmd>ClaudeCodeSelectModel<CR>', desc = 'Select Claude model' },
    { '<leader>ab', '<cmd>ClaudeCodeAdd %<CR>', desc = 'Add current buffer' },
    { '<leader>as', '<cmd>ClaudeCodeSend<CR>', mode = 'v', desc = 'Send to Claude' },
    { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<CR>', desc = 'Accept diff' },
    { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<CR>', desc = 'Deny diff' },
  },
}
