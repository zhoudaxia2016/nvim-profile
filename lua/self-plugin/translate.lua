local cmd, api, fn = vim.cmd, vim.api, vim.fn
cmd('hi Translate guifg=#bbded6 guibg=transparent')
function Translate()
  cmd 'normal! viwy'
  local result = {}
  local id
  local function callback(_, r)
    table.insert(result, r)
  end
  local function close()
    table.foreach(result, function(k, v) result[k] = string.gsub(v, "^%s*(.-)%s*$", "%1") end)
    local buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_lines(buf, 0, -1, true, result)
    id = api.nvim_open_win(buf, false, { style = 'minimal', relative = 'cursor', row = 1, col = 0, width = 10, height = 3, border = 'single' })
    api.nvim_win_set_option(id, 'winhl', 'Normal:Translate')
    cmd("au CursorMoved,CmdLineEnter * ++once call v:lua.Translate_handleCursorMove()")
  end
  function Translate_handleCursorMove()
    if id and api.nvim_win_is_valid(id) then
      api.nvim_win_close(id, true)
    end
  end
  fn['job#start']('trans -no-ansi :zh --brief ' .. fn.getreg('0'), { out_cb = callback, close_cb = close })
end

vim.api.nvim_set_keymap('n', '<leader>t', ':call v:lua.Translate()<cr>', {})
