local fzfBuiltins = require('self-plugin.fzf.builtin')
local getRoot = require('util').getRoot
local run = require('self-plugin.fzf').run
local previewer = require('self-plugin.fzf.previewer')

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

vim.api.nvim_create_autocmd('VimEnter', {
  pattern = '*',
  callback = function()
    -- TODO: 因为参数是[nvim, --embed]，所以长度为2。需优化判断
    if #vim.v.argv == 2 then
      fzfBuiltins.oldFiles()
    end
  end
})
vim.keymap.set('n', '<c-f>r', function()
  fzfBuiltins.oldFiles()
end)
