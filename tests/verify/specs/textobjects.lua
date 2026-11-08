local h = ...

-- mini.ai's "next" textobjects move off an/in, so 0.12's incremental
-- selection (an/in, ]n/[n) answers there.
local mini_next = {
  { mode = 'x', lhs = 'aN', desc = 'Around next textobject' },
  { mode = 'o', lhs = 'aN', desc = 'Around next textobject' },
  { mode = 'x', lhs = 'iN', desc = 'Inside next textobject' },
  { mode = 'o', lhs = 'iN', desc = 'Inside next textobject' },
}

for _, case in ipairs(mini_next) do
  local mode, lhs, desc = case.mode, case.lhs, case.desc
  h.test(('textobjects: %s %s is mini.ai "next"'):format(mode, lhs), function()
    local m = h.map(mode, lhs)
    h.ok(m, lhs .. ' is not mapped in ' .. mode)
    h.eq(m.desc, desc, lhs .. ' desc')
  end)
end

-- 0.12's own incremental selection, by the descriptions its runtime gives them.
local native_selection = {
  { mode = 'x', lhs = 'an', desc = 'Select parent (outer) node' },
  { mode = 'o', lhs = 'an', desc = 'Select parent (outer) node' },
  { mode = 'x', lhs = 'in', desc = 'Select child (inner) node' },
  { mode = 'o', lhs = 'in', desc = 'Select child (inner) node' },
  { mode = 'x', lhs = ']n', desc = 'Select next node' },
  { mode = 'x', lhs = '[n', desc = 'Select previous node' },
}

for _, case in ipairs(native_selection) do
  local mode, lhs, desc = case.mode, case.lhs, case.desc
  h.test(('textobjects: %s %s is the 0.12 incremental selection'):format(mode, lhs), function()
    local m = h.map(mode, lhs)
    h.ok(m, lhs .. ' is not mapped in ' .. mode)
    h.eq(m.desc, desc, lhs .. ' desc')
  end)
end
