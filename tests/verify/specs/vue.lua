local h = ...

-- vtsls sees inside a `.vue` file only through `@vue/typescript-plugin` (without
-- it, hover is empty), and attaching proves nothing about the plugin. So ask
-- for a type from `<script setup>`.
h.test('vue: script types resolve through the Vue TS plugin', function()
  h.expect_servers('src/App.vue', { includes = { 'vtsls' } })
  local buf = vim.api.nvim_get_current_buf()
  -- `const label = 'Clicked'`: a literal, so its type doesn't depend on `vue`
  -- being installed in the fixture.
  local ok, text = h.hover_until(buf, 'vtsls', h.position_of(buf, 'label'), function(t)
    return t:find('"Clicked"', 1, true) ~= nil
  end)
  h.ok(ok, 'hover on `label` lacks its type "Clicked" (hover: ' .. text .. ')')
end)
