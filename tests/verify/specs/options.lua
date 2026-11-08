local h = ...

h.test('options: fold column is 1 wide', function()
  h.eq(h.opt 'foldcolumn', '1', 'foldcolumn')
end)

h.test('options: folds start open', function()
  h.eq(h.opt 'foldlevelstart', 99, 'foldlevelstart')
  h.eq(h.opt 'foldlevel', 99, 'foldlevel')
end)

h.test('options: fixture buffers get the fold column', function()
  local buf = h.open 'lua/sample.lua'
  h.eq(h.opt('foldcolumn', buf), '1', 'foldcolumn in lua/sample.lua')
end)
