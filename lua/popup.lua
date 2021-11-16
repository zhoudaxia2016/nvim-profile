local api = vim.api
local popupInputBufName = '__popup-input-buf__'
local popupMenuBufName = '__popup-menu-buf__'
local popupInputBuf
local popupMenuBuf
local popupInputWin
local popupMenuWin
local selectLine = 0
vim.cmd('au BufEnter ' .. popupInputBufName .. ' startinsert')
local selectLineHighlightName = 'PopupSelectLine'
vim.cmd('hi ' .. selectLineHighlightName .. ' guifg=#17223b guibg=#b689b0')
vim.cmd('hi PopupNormal guifg=#bbded6 guibg=transparent')
local ns = api.nvim_create_namespace('popup')
local menuLen
local cb
local function hilightSelectLine()
  api.nvim_buf_clear_namespace(popupMenuBuf, ns, 0, -1)
  api.nvim_buf_add_highlight(popupMenuBuf, ns, selectLineHighlightName, selectLine, 0, -1)
end
function PopupClose()
  api.nvim_win_hide(popupInputWin)
  api.nvim_win_hide(popupMenuWin)
end
function PopupMoveMenu(n)
  selectLine = math.fmod(selectLine + n, menuLen)
  if (selectLine == -1) then
    selectLine = menuLen - 1
  end
  hilightSelectLine()
  return ''
end
function PopupConfirm()
  PopupClose()
  cb(selectLine)
end
function Popup(menus, cbf)
  cb = cbf
  menuLen = table.getn(menus)
  if popupInputBuf == nil then
    popupInputBuf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(popupInputBuf, popupInputBufName)
    api.nvim_buf_set_keymap(popupInputBuf, 'i', '<down>', 'v:lua.PopupMoveMenu(1)', { expr = true })
    api.nvim_buf_set_keymap(popupInputBuf, 'i', '<up>', 'v:lua.PopupMoveMenu(-1)', { expr = true })
    api.nvim_buf_set_keymap(popupInputBuf, 'i', '<enter>', '<Cmd>call v:lua.PopupConfirm()<cr>', { silent = true, noremap=true })
  end
  if popupMenuBuf == nil then
    popupMenuBuf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(popupMenuBuf, popupMenuBufName)
  end
  local content = {}
  for _, v in pairs(menus) do
    table.insert(content, v.text)
  end
  api.nvim_buf_set_lines(popupInputBuf, 0, -1, true, {''})
  api.nvim_buf_set_lines(popupMenuBuf, 0, -1, true, content)
  selectLine = 0
  local popupWidth = 50
  local popupX = (vim.o.columns - popupWidth) / 2
  popupInputWin = api.nvim_open_win(popupInputBuf, 1, { style = 'minimal', relative = 'editor', row = 0, col = popupX, width = popupWidth, height = 1, border = 'single', anchor='SW' })
  api.nvim_win_set_option(popupInputWin, 'winhl', 'Normal:PopupNormal')
  vim.defer_fn(function()
    popupMenuWin = api.nvim_open_win(popupMenuBuf, false, { style = 'minimal', relative = 'win', win = popupInputWin, row = 1, col = -1, width = popupWidth, height = table.getn(content), border = 'single' })
    api.nvim_win_call(popupMenuWin, hilightSelectLine)
    api.nvim_win_set_option(popupMenuWin, 'winhl', 'Normal:PopupNormal')
  end, 10)
end

function SearchFilePopup()
  local files = {
    { text = 'abc' },
    { text = 'def' },
    { text = 'haha' },
    { text = 'enen' },
    { text = 'aaaa' }
  }
  Popup(files, function(_)
    print(files[_ + 1].text)
  end)
end

api.nvim_set_keymap('n', '<c-p>', ':call v:lua.SearchFilePopup()<cr>', {})
