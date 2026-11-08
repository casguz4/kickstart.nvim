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

h.test("options: colorscheme is the catppuccin plugin's, transparent", function()
  -- 0.12 ships its own `catppuccin` scheme (colors_name 'catppuccin'). The
  -- plugin names itself after its flavour, mocha by default.
  h.eq(vim.g.colors_name, 'catppuccin-mocha', 'colors_name')
  h.eq(vim.api.nvim_get_hl(0, { name = 'Normal' }).bg, nil, 'Normal background (transparent_background)')
end)
