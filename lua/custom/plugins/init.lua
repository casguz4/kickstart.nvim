vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- File I/O
vim.keymap.set('n', '<leader>fs', ':w<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>fq', ':q<CR>', { desc = 'Quit file' })
vim.keymap.set('n', '<leader>fQ', ':qa<CR>', { desc = 'Quit all files' })
vim.keymap.set('n', '<leader>fS', ':qa<CR>', { desc = 'Save & Quit all files' })

return {}
