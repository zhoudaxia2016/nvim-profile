local function cb()
  local formatoptions = vim.o.formatoptions
  vim.o.formatoptions = ''
  vim.defer_fn(function()
    vim.o.formatoptions = formatoptions
  end, 0)
  return 'o'
end
vim.keymap.set('n', '<m-o>', cb, {expr = true})
