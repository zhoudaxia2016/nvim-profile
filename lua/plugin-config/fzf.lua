local fzfBuiltins = require('self-plugin.fzf.builtin')
local getRoot = require('util').getRoot

vim.keymap.set('n', '<cr>E', function()
  fzfBuiltins.findFile(vim.fn.getcwd())
end, {desc = 'Search files in current directory'})
vim.keymap.set('n', '<cr>e', function()
  fzfBuiltins.findFile(getRoot())
end, {desc = 'Search files in current projects'})

vim.keymap.set('n', '<cr>F', function()
  fzfBuiltins.rgSearch(vim.fn.getcwd())
end, {desc = 'Search with rg in current directory'})
vim.keymap.set('n', '<cr>f', function()
  fzfBuiltins.rgSearch(getRoot())
end, {desc = 'Search with rg in current projects'})
vim.keymap.set('n', '<cr><m-f>', function()
  vim.ui.input({ prompt = 'Enter ripgrep options: '}, function(input)
    if input == nil then
      return
    end
    fzfBuiltins.rgSearch(getRoot(), input)
  end)
end, {desc = 'Search with rg and options'})

vim.keymap.set('n', '<c-f>l', function()
  fzfBuiltins.searchLines()
end, {desc = 'Search lines in current buffer'})

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
end, {desc = 'Show old files'})

vim.keymap.set('n', '<cr>b', function()
  fzfBuiltins.buffers()
end, {desc = 'Show all buffers and jump to'})

vim.keymap.set('n', '<cr>c', function()
  fzfBuiltins.clearBuffer()
end, {desc = 'Show all buffers and clear'})

vim.keymap.set('n', '<cr>j', function()
  fzfBuiltins.jumps()
end, {desc = 'Show jumps'})

vim.keymap.set('n', '<cr>m', function()
  fzfBuiltins.changes()
end, {desc = 'Show changes'})

vim.keymap.set('n', '<cr>a', function()
  fzfBuiltins.nvimApis()
end, {desc = 'Show nvim apis'})

vim.keymap.set('n', '<cr>z', function()
  fzfBuiltins.z()
end, {desc = 'Show directorys recently visited'})

vim.api.nvim_create_user_command('FzfKeymaps', function()
  fzfBuiltins.keymaps()
end, {desc = 'Show all keymaps'})
