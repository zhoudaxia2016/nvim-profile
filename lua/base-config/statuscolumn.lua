local gitsign = require('self-plugin.gitsign')
gitsign.setup()

function StatusColumn()
  local filetype = vim.o.filetype
  if (filetype == 'help') then
    return ''
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
  return string.format('%s%%s %s ', gitsign.sign(), lineNumInfo)
end

vim.o.stc = '%{%v:lua.StatusColumn()%}'
