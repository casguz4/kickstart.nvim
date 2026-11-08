local h = ...

local STEP_TIMEOUT_MS = 5000
local TICK_MS = 20

-- Run `script` while Insert mode is active, the way a user types: keys fed
-- with `type` go through mappings, and `wait_for` lets the event loop run
-- (completion menus are async) until a condition holds. Returns the script's
-- error, if it raised one.
local function in_insert_mode(script)
  local failure
  local co = coroutine.create(script)
  local api = {
    type = function(keys)
      vim.api.nvim_feedkeys(vim.keycode(keys), 'mt', false)
      coroutine.yield()
    end,
    wait_for = function(cond)
      local deadline = vim.uv.now() + STEP_TIMEOUT_MS
      while not cond() do
        if vim.uv.now() > deadline then
          return false
        end
        coroutine.yield()
      end
      return true
    end,
  }
  local timer = assert(vim.uv.new_timer())
  timer:start(
    TICK_MS,
    TICK_MS,
    vim.schedule_wrap(function()
      if coroutine.status(co) == 'dead' then
        return
      end
      local ok, err = coroutine.resume(co, api)
      if not ok then
        failure = err
      end
      if coroutine.status(co) == 'dead' then
        timer:stop()
        timer:close()
        vim.cmd 'stopinsert'
      end
    end)
  )
  -- Typed keys only run when Nvim reads input. `x!` reads the typeahead and,
  -- in Insert mode, keeps reading until the script ends Insert mode; leaving
  -- it some other way (a snippet selecting a placeholder) returns early, so
  -- keep going until the script is done.
  vim.api.nvim_feedkeys('i', 'n', false)
  while coroutine.status(co) ~= 'dead' do
    vim.api.nvim_feedkeys('', 'x!', false)
    vim.wait(TICK_MS)
  end
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  return failure
end

-- friendly-snippets' Lua `ll`: `local ${1:varName} = ${2:value}`.
local function is_ll(item)
  return item ~= nil and item.source_id == 'snippets' and item.label == 'll'
end

h.test('completion: a friendly-snippets snippet expands and its tabstops jump', function()
  vim.cmd 'enew!'
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'lua'
  local cmp = require 'blink.cmp'

  local failure = in_insert_mode(function(ui)
    ui.type 'll'
    h.ok(
      ui.wait_for(function()
        return vim.iter(cmp.get_items()):any(is_ll)
      end),
      'the completion menu never offered the `ll` snippet'
    )
    for _ = 1, #cmp.get_items() do
      if is_ll(cmp.get_selected_item()) then
        break
      end
      ui.type '<C-n>'
    end
    h.ok(is_ll(cmp.get_selected_item()), 'could not select the `ll` snippet in the menu')

    -- Accept, type over the first placeholder, jump, type over the second.
    ui.type '<C-y>'
    ui.wait_for(function()
      return vim.api.nvim_get_current_line():find('varName', 1, true) ~= nil
    end)
    ui.type 'name'
    ui.type '<Tab>'
    ui.type 'value2'
  end)
  h.ok(failure == nil, tostring(failure))

  h.eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { 'local name = value2' }, 'buffer after expanding `ll`')
end)

h.test('completion: attached clients advertise blink.cmp completion capabilities', function()
  h.expect_servers('lua/sample.lua', { includes = { 'lua_ls' } })
  local client = vim.lsp.get_clients({ bufnr = 0, name = 'lua_ls' })[1]
  local completion = vim.tbl_get(client.capabilities, 'textDocument', 'completion') or {}
  local item = completion.completionItem or {}
  -- Nvim 0.12's own client capabilities have none of these; blink.cmp adds them.
  h.eq(completion.insertTextMode, 1, 'completion.insertTextMode')
  h.eq(item.insertTextModeSupport, { valueSet = { 1 } }, 'completionItem.insertTextModeSupport')
  local resolve = vim.tbl_get(item, 'resolveSupport', 'properties') or {}
  for _, prop in ipairs { 'detail', 'data' } do
    h.ok(vim.list_contains(resolve, prop), 'completionItem.resolveSupport lacks ' .. prop .. ': ' .. vim.inspect(resolve))
  end
  local defaults = vim.tbl_get(completion, 'completionList', 'itemDefaults') or {}
  h.ok(vim.list_contains(defaults, 'commitCharacters'), 'completionList.itemDefaults lacks commitCharacters: ' .. vim.inspect(defaults))
end)
