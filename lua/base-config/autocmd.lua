vim.api.nvim_create_autocmd('TextYankPost', {
  pattern = '*',
  callback = function()
    vim.highlight.on_yank { higroup='DiffText', timeout=700 }
  end
})

local lastClosedTab
vim.api.nvim_create_autocmd('TabLeave', {
  pattern = '*',
  callback = function()
    lastClosedTab = vim.fn.tabpagenr()
  end
})
vim.api.nvim_create_autocmd('TabClosed', {
  pattern = '*',
  callback = function()
    local curtab = vim.fn.tabpagenr()
    if (curtab == 1) then
      return
    end
    if (curtab == lastClosedTab) then
      local tabonleft = curtab - 1
      vim.cmd(tabonleft .. 'tabnext')
    end
  end
})
