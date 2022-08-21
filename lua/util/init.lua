module = {}
function module.starts(s, start)
  return string.sub(s, 1, string.len(start)) == start
end

function module.trim(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

function module.isSpecialBuf()
  return module.hasValue({'qf', 'netrw', 'help', ''}, vim.o.filetype)
end

function module.hasValue(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

function module.map(mode, key, command, opt, bufnr)
  local options = { noremap = true, silent = true }
  if bufnr ~= nil then
    options.buffer = bufnr
  end
  if opt then
    options = vim.tbl_extend("force", options, opt)
  end
  vim.keymap.set(mode, key, command, options)
end

return module
