local lastLeavedTab
vim.api.nvim_create_autocmd('TabLeave', {
  pattern = '*',
  callback = function()
    lastLeavedTab = vim.fn.tabpagenr()
  end
})
vim.api.nvim_create_autocmd('TabClosed', {
  pattern = '*',
  callback = function()
    local curtab = vim.fn.tabpagenr()
    if (curtab == 1) then
      return
    end
    if (curtab == lastLeavedTab) then
      local tabonleft = curtab - 1
      vim.cmd(tabonleft .. 'tabnext')
    end
  end
})
