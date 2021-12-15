local jobstart = require('util.jobstart')
local util = require('util')
function CopyToSystem()
  local temp = vim.fn.tempname()
  local fd = io.open(temp, 'w')
  io.output(fd)
  io.write(vim.fn.getreg('"'))
  io.close(fd)
  jobstart('clip.exe < ' .. temp)
end
vim.api.nvim_set_keymap('n', '<m-o>', '<Cmd>call v:lua.CopyToSystem()<cr>', { silent = true })

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
