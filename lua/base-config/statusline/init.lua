local o = vim.o
local hlgs = require('base-config.statusline.hlgs')
local utils = require('base-config.statusline.utils')
local config = require('base-config.statusline.config')

-- highlight setup
for _, v in pairs(hlgs) do
  vim.cmd(string.format([[hi %s guifg=%s guibg=%s]], v.name, v.fg, v.bg))
end

function Statusline()
  local statusline = ''
  local function concatStatusline(list)
    for i, v in pairs(list) do
      local item
      if v.text then
        item = v.text
      elseif v.label then
        local statuslineWinId = vim.g.statuslineWinId or vim.api.nvim_get_current_win()
        if type(v.label) == 'string' then
          item = vim.api.nvim_eval_statusline(v.label, {winid = statuslineWinId}).str
        else
          item = v.label(statuslineWinId)
        end
      end
      if v.handler then
        item = utils.registerFn(i, v.handler, item)
      end
      if v.hlg then
        item = ('%%#%s#%s'):format(v.hlg, item)
      end
      statusline = statusline .. item
    end
  end
  concatStatusline(config.leftList)
  statusline = statusline .. '%=%<'
  concatStatusline(config.rightList)
  return statusline
end

o.statusline = '%!v:lua.Statusline()'
o.laststatus = 3
