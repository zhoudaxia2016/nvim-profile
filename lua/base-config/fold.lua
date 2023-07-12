local util = require('util')
local opt = vim.opt

opt.foldopen:append('jump')
opt.foldopen:append('search')
opt.foldopen:append('hor')

vim.api.nvim_create_autocmd('FileType', {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if util.isSpecialBuf() then
        return
      end
      if vim.fn.line('$') > 500 then
        vim.wo.foldmethod = 'indent'
        vim.wo.foldlevel = 3
        vim.wo.foldenable = true
      else
        vim.wo.foldenable = false
      end
    end, 0)
  end
})
