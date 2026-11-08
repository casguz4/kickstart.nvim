-- Folding policy: LSP folding ranges when a server has them, else treesitter
-- when a parser runs (init.lua's treesitter FileType handler), else indent
-- (the global 'foldmethod'). A server's folds close the imports on open.
local M = {}

-- Fold every window showing `buf` with `foldexpr`.
local function fold_with(buf, foldexpr)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win][0].foldmethod = 'expr'
    vim.wo[win][0].foldexpr = foldexpr
  end
end

---Whether `client` gives folding ranges for `buf`.
---@param client vim.lsp.Client?
---@param buf integer
---@return boolean
local function server_folds(client, buf)
  return client ~= nil and client:supports_method('textDocument/foldingRange', buf)
end

---Fold `buf` with treesitter. Call it once its parser has started.
---@param buf integer
function M.use_treesitter(buf)
  fold_with(buf, 'v:lua.vim.treesitter.foldexpr()')
end

---A server with folding ranges takes over from treesitter/indent in every
---window showing the buffer.
function M.setup()
  local group = vim.api.nvim_create_augroup('custom-lsp-folding', { clear = true })
  local function use_lsp(buf)
    fold_with(buf, 'v:lua.vim.lsp.foldexpr()')
  end

  vim.api.nvim_create_autocmd('LspAttach', {
    group = group,
    callback = function(args)
      if server_folds(vim.lsp.get_client_by_id(args.data.client_id), args.buf) then
        use_lsp(args.buf)
      end
    end,
  })
  -- A server that attached while the buffer was in no window set nothing, so
  -- the window it is shown in next still has the treesitter/indent folds.
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    callback = function(args)
      for _, client in ipairs(vim.lsp.get_clients { bufnr = args.buf }) do
        if server_folds(client, args.buf) then
          use_lsp(args.buf)
          return
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd('LspNotify', {
    group = group,
    callback = function(args)
      if args.data.method ~= 'textDocument/didOpen' or not server_folds(vim.lsp.get_client_by_id(args.data.client_id), args.buf) then
        return
      end
      -- A client's didOpen goes out before its LspAttach, when LSP folding
      -- hasn't started for the buffer and foldclose() does nothing. Evaluating
      -- the foldexpr starts it on the next tick; close the imports after that.
      vim.api.nvim_buf_call(args.buf, function()
        vim.lsp.foldexpr(1)
      end)
      vim.schedule(function()
        local win = vim.fn.bufwinid(args.buf)
        if win ~= -1 then
          vim.lsp.foldclose('imports', win)
        end
      end)
    end,
  })
end

return M
