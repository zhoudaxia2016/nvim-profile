local loadColorSet = require('nord.util').loadColorSet
local palettes = require('nord.named_colors')

local themes = {
  ['TabLineInfoFill'] = { fg = palettes.purple },
  ['TabLineInfo'] = { fg = palettes.purple, bg = palettes.dark_gray },
}
loadColorSet(themes)

local fn = vim.fn
local api = vim.api

local start = 1
local stop = 1
local start_len = -1
local stop_len = -1

local function tabLabel(n)
  local winlist = api.nvim_tabpage_list_wins(n)
  local activeBuf
  if #winlist == 1 then
    activeBuf = api.nvim_win_get_buf(winlist[1])
  else
    for _, win in pairs(winlist) do
      local buf = api.nvim_win_get_buf(win)
      if api.nvim_get_option_value('filetype', {buf = buf}) ~= 'netrw' then
        activeBuf = buf
        break
      end
    end
  end
  local isModify = api.nvim_get_option_value("mod", {buf = activeBuf})
  local modifyMark = isModify and '+ ' or ''
  return modifyMark .. fn.fnamemodify(api.nvim_buf_get_name(activeBuf), ':t')
end

function MyTabLine()
  local tabpages = {}
  local select_index = fn.tabpagenr()
  local count = fn.tabpagenr('$')
  local info = string.format(' [%s/%s] ', select_index, count)
  local capacity = vim.o.columns - #info
  for _, tabpage in pairs(api.nvim_list_tabpages()) do
    local text = string.format(' %s ', tabLabel(tabpage))
    table.insert(tabpages, { text = text })
  end

  local total_char = 0

  -- 当前选中tab不在可视区域，重新计算
  if select_index < start or select_index > stop then
    start = select_index
    stop = select_index
    total_char = #tabpages[select_index].text
  else
    for i = start, stop do
      total_char = total_char + #tabpages[i].text
    end
  end

  -- 还有空间，往前显示
  while total_char < capacity and start > 1 do
    start = start - 1
    total_char = total_char + #tabpages[start].text
  end
  -- 还有空间，往后显示
  while total_char < capacity and stop < count do
    stop = stop + 1
    total_char = total_char + #tabpages[stop].text
  end

  -- 超出屏幕，裁剪
  if total_char > capacity then
    if stop == select_index then
      start_len = #tabpages[start].text - (total_char - capacity)
      stop_len = -1
    else
      stop_len = #tabpages[stop].text - (total_char - capacity)
      start_len = -1
    end
  end

  local s = ''
  for i = start, stop do
    if i == select_index then
      s = s .. '%#TabLineSel#'
    else
      s = s .. '%#TabLine#'
    end
    local tabpage = tabpages[i]
    local text = tabpage.text
    if i == start and start_len ~= -1 then
      text = '<' .. string.sub(text, #text - start_len, #text)
    end
    if i == stop and stop_len ~= -1 then
      text = string.sub(text, 1, stop_len - 1) .. '>'
    end
    s = s .. text
  end

  -- 默认info背景色和TabLine一致
  -- 若TabLine有剩余空间，则背景色和TabLineFill一致
  local info_color_group = 'TabLineInfo'
  if total_char < capacity then
    info_color_group = 'TabLineInfoFill'
  end

  s = s .. '%#TabLineFill#%T'
  s = s .. '%=%#TabLine#'
  s = string.format('%s%%#%s#%s', s, info_color_group, info)

  return s
end

vim.o.tabline='%!v:lua.MyTabLine()'
