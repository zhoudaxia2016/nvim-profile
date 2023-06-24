local fzfBuiltins = require('self-plugin.fzf.builtin')
local getRoot = require('util').getRoot

vim.keymap.set('n', '<c-f>O', function()
  fzfBuiltins.findFile(vim.fn.getcwd())
end, {})
vim.keymap.set('n', '<c-f>o', function()
  fzfBuiltins.findFile(getRoot())
end, {})

vim.keymap.set('n', '<c-f><c-F>', function()
  fzfBuiltins.rgSearch(vim.fn.getcwd())
end)
vim.keymap.set('n', '<c-f><c-f>', function()
  fzfBuiltins.rgSearch(getRoot())
end)

vim.keymap.set('n', '<c-f>l', function()
  fzfBuiltins.searchLines()
end)
