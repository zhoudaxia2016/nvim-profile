local jobstart = require('util.jobstart')
function CopyToSystem()
  local temp = vim.fn.tempname()
  print(temp)
  local fd = io.open(temp, 'w')
  io.output(fd)
  io.write(vim.fn.getreg('"'))
  io.close(fd)
  jobstart('clip.exe < ' .. temp)
end
vim.api.nvim_set_keymap('n', '<m-o>', '<Cmd>call v:lua.CopyToSystem()<cr>', { silent = true })

