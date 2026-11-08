local h = ...

-- vtsls loads the project before it answers; give it the same budget the
-- harness gives a server to attach. Each request gets its own shorter wait.
local TYPE_TIMEOUT_MS = 20000
local REQUEST_TIMEOUT_MS = 5000
local RETRY_MS = 500

-- The first position of `word` in `buf`, as an LSP position.
local function position_of(buf, word)
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local col = line:find(word, 1, true)
    if col then
      return { line = i - 1, character = col - 1 }
    end
  end
  error(string.format('`%s` not found in the buffer', word), 2)
end

-- vtsls sees inside a `.vue` file only through `@vue/typescript-plugin` (without
-- it, hover is empty), and attaching proves nothing about the plugin. So ask
-- for a type from `<script setup>`.
h.test('vue: script types resolve through the Vue TS plugin', function()
  h.expect_servers('src/App.vue', { includes = { 'vtsls' } })
  local buf = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = buf, name = 'vtsls' })[1]
  -- `const label = 'Clicked'`: a literal, so its type doesn't depend on `vue`
  -- being installed in the fixture.
  local params = { textDocument = { uri = vim.uri_from_bufnr(buf) }, position = position_of(buf, 'label') }

  local hover_text = ''
  local function typed()
    return hover_text:find('"Clicked"', 1, true) ~= nil
  end

  -- vtsls answers empty until the project loads, so re-ask until it has a type.
  -- One request at a time: a request fired from inside a vim.wait predicate is
  -- answered instantly, so the predicate floods the server and the wait never ends.
  local deadline = vim.uv.now() + TYPE_TIMEOUT_MS
  repeat
    local answered = false
    client:request('textDocument/hover', params, function(_, result)
      -- vtsls sends a bare MarkedString; other servers send MarkupContent.
      local contents = result and result.contents or ''
      hover_text = type(contents) == 'string' and contents or contents.value or ''
      answered = true
    end, buf)
    vim.wait(REQUEST_TIMEOUT_MS, function()
      return answered
    end, 50)
    if typed() then
      break
    end
    vim.wait(RETRY_MS)
  until vim.uv.now() > deadline

  h.ok(typed(), 'hover on `label` lacks its type "Clicked" (hover: ' .. hover_text .. ')')
end)
