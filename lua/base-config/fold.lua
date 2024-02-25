local util = require('util')
local opt = vim.opt

opt.foldopen:append('jump')
opt.foldopen:append('search')
opt.foldopen:append('hor')

vim.o.foldtext = ''
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.o.foldlevel = 2
vim.o.foldminlines = 16

vim.api.nvim_create_autocmd('FileType', {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if util.isSpecialBuf() then
        return
      end
      vim.wo.foldenable = true
    end, 0)
  end
})
