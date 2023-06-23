local M = {}
function M.starts(s, start)
  return string.sub(s, 1, string.len(start)) == start
end

function M.trim(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

function M.isSpecialBuf()
  return M.hasValue({'qf', 'netrw', 'help', ''}, vim.o.filetype)
end

function M.hasValue(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

function M.copy(text)
  local temp = vim.fn.tempname()
  local fd = io.open(temp, 'w')
  io.output(fd)
  io.write(text)
  io.close(fd)
  vim.fn.jobstart('clip.exe < ' .. temp)
end

function M.map(mode, key, command, opt, bufnr)
  local options = { noremap = true, silent = true }
  if bufnr ~= nil then
    options.buffer = bufnr
  end
  if opt then
    options = vim.tbl_extend("force", options, opt)
  end
  vim.keymap.set(mode, key, command, options)
end

M.getRoot = function ()
  return require('lspconfig.util').root_pattern('package.json', '.git')(vim.fn.getcwd())
end

return M
