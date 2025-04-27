--- https://gist.github.com/kr-alt/24aaf4bad50d603c3c6a270502e57209
local root_files = {
  'tsconfig.base.json',
  'tsconfig.json',
  'jsconfig.json',
  'package.json',
  '.git',
}
local paths = vim.fs.find(root_files, { stop = vim.env.HOME })
local root_dir = vim.fs.dirname(paths[1])

-- root directory was not found
if root_dir == nil then
  return
end

---@type vim.lsp.Config
local M = {}

M.cmd = {
  vim.env.TSGOPATH .. '/built/local/tsgo',
  'lsp',
  '--stdio',
}

M.filetypes = {
  'javascript',
  'javascriptreact',
  'typescript',
  'typescriptreact',
}

M.root_dir = root_dir

return M
