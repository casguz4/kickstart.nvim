-- Runs via --cmd, before the config loads. Records ERROR-level notifications so
-- the harness can report errors that never reach :messages as an E-number.
_G.__verify_notify_errors = {}

local notify = vim.notify
vim.notify = function(msg, level, opts)
  if level and level >= vim.log.levels.ERROR then
    table.insert(_G.__verify_notify_errors, tostring(msg))
  end
  return notify(msg, level, opts)
end
