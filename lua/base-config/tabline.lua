local fn = vim.fn
local api = vim.api
function MyTabLine()
  local s = ''
  for i, tabpage in pairs(api.nvim_list_tabpages()) do
    -- select the highlighting
    if i == fn.tabpagenr() then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end

    -- the label is made by MyTabLabel()
    s = s .. string.format(' %s ', MyTabLabel(tabpage))
  end

  -- after the last tab fill with TabLineFill and reset tab page nr
  s = s .. '%#TabLineFill#%T'

  -- right-align the label to close the current tab page
  if fn.tabpagenr('$') > 1 then
    s = s .. '%=%#TabLine#%'
  end

  return s
end

function MyTabLabel(n)
  local winlist = api.nvim_tabpage_list_wins(n)
  local activeBuf
  if #winlist == 1 then
    activeBuf = api.nvim_win_get_buf(winlist[1])
  else
    for _, win in pairs(winlist) do
      local buf = api.nvim_win_get_buf(win)
      if api.nvim_buf_get_option(buf, 'filetype') ~= 'netrw' then
        activeBuf = buf
        break
      end
    end
  end
  local modifyMark = api.nvim_buf_get_option(activeBuf, "mod") and '+ ' or ''
  print(api.nvim_buf_get_option(activeBuf, "mod"))
  return modifyMark .. fn.fnamemodify(api.nvim_buf_get_name(activeBuf), ':t')
end
vim.o.tabline='%!v:lua.MyTabLine()'
