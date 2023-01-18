local gitsign = require('self-plugin.gitsign')
gitsign.setup()

function StatusColumn()
  local filetype = vim.o.filetype
  local emptyFileType = {'help', 'gitcommit', 'man'}
  if (vim.tbl_contains(emptyFileType, filetype)) then
    return ''
  end
  local onlyLineNrFileType = {'qf'}
  if (vim.tbl_contains(onlyLineNrFileType, filetype)) then
    return '%l'
  end
  local cursorLnum = vim.fn.line('.')
  local lnum = vim.v.lnum
  local isCursorLine = cursorLnum == lnum
  local lineNumInfo = vim.v.virtnum == 0
    and string.format('%%=%%<%%#%s#%s ', isCursorLine and 'CursorLineNr' or 'LineNr', isCursorLine and lnum or vim.v.relnum)
    or ''
  if (filetype == 'netrw') then
    return lineNumInfo
  end
  return string.format('%s%%s%s', gitsign.sign(), lineNumInfo)
end

vim.o.stc = '%{%v:lua.StatusColumn()%}'
