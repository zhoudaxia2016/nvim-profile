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

M.createColorGroup = function(base, prefix, link)
  local hl = link and vim.api.nvim_get_hl(0, {name = link}) or {}
  for k, v in pairs(base) do
    hl[k] = v
  end
  local name = prefix .. link
  vim.api.nvim_set_hl(0, name, hl)
  return name
end

return M
