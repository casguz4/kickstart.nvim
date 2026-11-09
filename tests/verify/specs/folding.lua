local h = ...

h.test('folding: the plugins it replaced are removed', function()
  h.expect_plugins {
    removed = { 'nvim-ufo', 'promise-async' },
  }
end)

-- Long enough for a server to answer its first foldingRange request.
local FOLD_TIMEOUT_MS = 20000

local LSP_FOLDEXPR = 'v:lua.vim.lsp.foldexpr()'
local TS_FOLDEXPR = 'v:lua.vim.treesitter.foldexpr()'

-- `foldclosed()` and `foldclosedend()` for a line, read in the buffer's window.
local function closed_range(buf, lnum)
  return vim.api.nvim_win_call(vim.fn.bufwinid(buf), function()
    return { vim.fn.foldclosed(lnum), vim.fn.foldclosedend(lnum) }
  end)
end

h.test('folding: an LSP buffer folds with the LSP foldexpr', function()
  h.expect_servers('src/index.ts', { includes = { 'tsc' } })
  local buf = vim.api.nvim_get_current_buf()
  h.eq(h.opt('foldmethod', buf), 'expr', 'foldmethod in src/index.ts')
  h.eq(h.opt('foldexpr', buf), LSP_FOLDEXPR, 'foldexpr in src/index.ts')
end)

h.test('folding: a server that attaches while the buffer is hidden still folds with LSP once shown', function()
  h.expect_servers('src/index.ts', { includes = { 'tsc' } })
  local path = h.sibling_copy 'src/folds.ts'
  -- Hide the new buffer in the same tick, before tsc attaches to it.
  local buf = h.open(path)
  h.open(vim.fn.tempname() .. '.txt')
  h.eq(vim.fn.bufwinid(buf), -1, 'the copy is still shown in a window')
  local attached = vim.wait(FOLD_TIMEOUT_MS, function()
    return vim.list_contains(h.servers(buf), 'tsc')
  end, 50)
  h.ok(attached, 'tsc did not attach to the hidden copy')
  h.open(path)
  h.eq(h.opt('foldexpr', buf), LSP_FOLDEXPR, 'foldexpr in the copy once shown')
end)

h.test('folding: a buffer with only a parser folds with treesitter', function()
  -- No server is configured for TOML; nvim-treesitter has its parser.
  h.expect_servers('stylua.toml', {})
  local buf = vim.api.nvim_get_current_buf()
  h.eq(h.servers(buf), {}, 'servers attached to stylua.toml')
  h.ok(vim.treesitter.highlighter.active[buf], 'no treesitter parser started in stylua.toml')
  h.eq(h.opt('foldmethod', buf), 'expr', 'foldmethod in stylua.toml')
  h.eq(h.opt('foldexpr', buf), TS_FOLDEXPR, 'foldexpr in stylua.toml')
end)

h.test('folding: a buffer with no parser or server folds by indent', function()
  local path = vim.fn.tempname() .. '.txt'
  vim.fn.writefile({ 'top', '  nested', '  nested' }, path)
  local buf = h.open(path)
  h.eq(vim.bo[buf].filetype, 'text', 'filetype of the .txt file')
  h.eq(h.servers(buf), {}, 'servers attached to the .txt file')
  h.eq(h.opt('foldmethod', buf), 'indent', 'foldmethod in a .txt file')
end)

h.test('folding: imports in a .ts file are closed after open', function()
  h.expect_servers('src/folds.ts', { includes = { 'tsc' } })
  local buf = vim.api.nvim_get_current_buf()
  local closed = vim.wait(FOLD_TIMEOUT_MS, function()
    return closed_range(buf, 1)[1] ~= -1
  end, 100)
  h.ok(closed, 'the import block in src/folds.ts is not folded closed')
  h.eq(closed_range(buf, 1), { 1, 2 }, 'closed fold over the imports (first, last line)')
  h.eq(closed_range(buf, 4)[1], -1, 'foldclosed() on the code after the imports')
end)

h.test('folding: closed folds show their first line, highlighted', function()
  h.eq(h.opt 'foldtext', '', 'foldtext')
end)

h.test('folding: the fold column hides nested level digits', function()
  local items = vim.split(h.opt 'fillchars', ',', { plain = true })
  h.ok(vim.list_contains(items, 'foldinner: '), "fillchars has no 'foldinner: ' item: " .. h.opt 'fillchars')
end)

h.test('folding: zR and zM are the built-in commands', function()
  h.eq(h.map('n', 'zR'), nil, 'zR mapping')
  h.eq(h.map('n', 'zM'), nil, 'zM mapping')
end)
