local util = require('util')

function ConfigFold()
  vim.defer_fn(function()
    if util.isSpecialBuf() then
      return
    end
    if vim.fn.line('$') > 80 then
      vim.o.foldmethod = 'indent'
      vim.o.foldlevel = 3
      vim.o.foldopen = 'jump'
    else
      vim.o.foldenable = false
    end
  end, 0)
end
