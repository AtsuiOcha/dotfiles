-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Exit insert mode with jj' })
-- remove this cursed mapping
vim.keymap.set('n', '<C-x>', '<cmd>echo "DON\'T YOU DARE!!!"<CR>', { desc = 'Prevent accidental close' })

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Enter terminal mode
vim.keymap.set('n', '<leader>tt', function()
  vim.cmd 'split' -- create a horizontal split
  vim.cmd 'resize 15' -- optional: set height to 15 lines
  vim.cmd 'terminal' -- open terminal in the split
  vim.cmd 'startinsert' -- go directly into insert mode
end, { desc = 'Open terminal below' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--  NOTE: These are handled by vim-tmux-navigator plugin
--
--  See `:help wincmd` for a list of all window commands

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Comment selected code with <leader>/ in visual mode
vim.keymap.set('v', '<leader>/', function()
  -- Exit visual mode before applying the comment to get the correct selection
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
  require('Comment.api').toggle.linewise(vim.fn.visualmode())
end, { desc = 'Toggle comment for selection' })

-- dismiss notifications
vim.keymap.set('n', '<leader>nd', function()
  require('noice').cmd 'dismiss'
end, { desc = 'Dismiss notifications' })

vim.keymap.set('n', '<leader>fd', function()
  vim.diagnostic.open_float(nil, {
    focus = true,
    scope = 'line',
    border = 'rounded',
    source = true,
  })
end, { desc = 'Show diagnostics in float' })
-- vim: ts=2 sts=2 sw=2 et
