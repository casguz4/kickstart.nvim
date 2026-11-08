-- Copilot inline suggestions from the native `copilot` language server
-- (lspconfig's config, Mason's copilot-language-server), shown as ghost text by
-- `vim.lsp.inline_completion`, never in the completion menu.
--
-- Off every session: the server isn't enabled at startup, so no process runs
-- and nothing reaches Copilot until <leader>tc turns it on. If the server asks
-- for a login, run :LspCopilotSignIn in a buffer it is attached to.
local M = {}

-- copilot.vim's default exclusions: buffers Copilot never attaches to.
local EXCLUDED_FILETYPES = { gitcommit = true, gitrebase = true, hgcommit = true, svn = true, cvs = true, [''] = true }
local EXCLUDED_BUFTYPES = { help = true, prompt = true, quickfix = true, terminal = true }

-- Calls `on_dir` (letting Copilot attach) only for an allowed buffer. The root
-- is the git root when there is one, as in lspconfig's config.
local function root_dir(bufnr, on_dir)
  if EXCLUDED_FILETYPES[vim.bo[bufnr].filetype] or EXCLUDED_BUFTYPES[vim.bo[bufnr].buftype] then
    return
  end
  on_dir(vim.fs.root(bufnr, '.git'))
end

local function toggle()
  if vim.lsp.is_enabled 'copilot' then
    vim.lsp.inline_completion.enable(false)
    -- Stops the server and detaches it from every buffer.
    vim.lsp.enable('copilot', false)
    vim.notify 'Copilot off'
  else
    vim.lsp.enable 'copilot'
    vim.lsp.inline_completion.enable(true)
    vim.notify 'Copilot on'
  end
end

function M.setup()
  vim.lsp.config('copilot', { root_dir = root_dir })

  vim.keymap.set('n', '<leader>tc', toggle, { desc = '[T]oggle [C]opilot' })

  vim.keymap.set('i', '<C-J>', function()
    if not vim.lsp.inline_completion.get() then
      return '<C-J>'
    end
  end, { expr = true, replace_keycodes = true, desc = 'Copilot: accept suggestion' })
  vim.keymap.set('i', '<M-]>', function()
    vim.lsp.inline_completion.select { count = 1 }
  end, { desc = 'Copilot: next suggestion' })
  vim.keymap.set('i', '<M-[>', function()
    vim.lsp.inline_completion.select { count = -1 }
  end, { desc = 'Copilot: previous suggestion' })
end

return M
