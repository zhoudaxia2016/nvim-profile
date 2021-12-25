local g = vim.g
local t = vim.t
local o = vim.o
local cmd = vim.cmd
local fn = vim.fn
local b = vim.b

g.netrw_banner = 0
g.netrw_list_hide = '^\\.'
g.netrw_bufsettings = "nonu rnu wrap"
g.netrw_use_noswf = 0
o.autochdir = true

function ToggleExplorer()
  -- 是否打开目录树buffer
  if t.expl_buf_num ~= nil then
    local expl_win_num = fn.bufwinnr(t.expl_buf_num)
    -- 打开了目录树窗口
    if expl_win_num ~= -1 then
      local cur_win_nr = fn.winnr()
      -- 先进入目录树窗口
      cmd(expl_win_num .. 'wincmd w')
      -- 是否已经在目录树窗口，是则关闭目录树，否则什么都用做
      if (cur_win_nr == expl_win_num) then
        cmd('close')
        local cur_win_nr = fn.winnr()
        cmd(cur_win_nr .. 'wincmd w')
        t.expl_buf_num = nil
      end
    else
      t.expl_buf_num = nil
    end
  else
    -- 没有目录树buffer，则打开，保存buf number
    cmd('1wincmd w')
    cmd('Lexplore ' .. fn.expand('%:p:h'))
    t.expl_buf_num = fn.bufnr("%")
  end
end

local map = require('util').map
local trim = require('util').trim
map('n', '<leader>d', ':call v:lua.ToggleExplorer()<cr>', { silent = true })

o.splitright = true

cmd('autocmd filetype netrw call v:lua.Netrw_mappings()')
function Netrw_mappings()
  local buf = fn.bufnr('%')
  map('n', 'f', ':call v:lua.SplitFile()<cr>', {}, buf)
  map('n', '(', ':call v:lua.CreateFile()<cr>', {}, buf)
  cmd('vertical res 20')
end

function SplitFile()
  local fn = GetCursorFile()
  cmd(string.format('silent vs %s/%s', b.netrw_curdir, fn))
  cmd('redraw!')
end

function CreateFile()
  local fn = vim.ui.input({
    prompt = 'Please enter filename: '
  }, function(fn)
    cmd(string.format('silent vs %s/%s', b.netrw_curdir, fn)) 
  end)
end

function GetCursorFile()
  return string.gsub(trim(fn.getline('.')), '%*', '')
end
