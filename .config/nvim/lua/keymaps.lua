
vim.api.nvim_set_keymap("i", "jj", "<Esc>", { noremap = false })

-- Telescope keymaps
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>gc', builtin.git_commits, {})
vim.keymap.set('n', '<leader>gb', builtin.git_branches, {})
vim.keymap.set('n', '<leader>gs', builtin.git_status, {})


