vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    if vim.o.filetype:match('commit') == nil then
      local l = vim.fn.line("'\"")
      if l >= 1 and l <= vim.fn.line('$') then
        vim.cmd('normal! g`"')
      else
        vim.cmd('normal! G')
      end
    end
  end,
  once = true
})
