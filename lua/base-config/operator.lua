OperatorFunc = nil
local jobstart = require('util.jobstart')
local prefix = '<m-q>'
local function newOperator(key, fn)
  vim.keymap.set('n', prefix .. '<m-' .. key .. '>', function()
    OperatorFunc = fn
    -- TODO use lua function: vim.o.operatorfunc = fn
    vim.o.operatorfunc = 'v:lua.OperatorFunc'
    return 'g@'
  end, { expr = true, buffer = 0, silent = ture, noremap = true })
end

local function getRange()
  local start = vim.fn.line("'['")
  local stop = vim.fn.line("']'")
  return start, stop
end

newOperator('o', function(type)
  vim.cmd "normal `[v`]y"
  local temp = vim.fn.tempname()
  local fd = io.open(temp, 'w')
  io.output(fd)
  io.write(vim.fn.getreg('"'))
  io.close(fd)
  jobstart('clip.exe < ' .. temp)
end)
