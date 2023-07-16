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

local map = require('util').map
local trim = require('util').trim
map('n', '<leader>d', function()
  -- ToggleExplorer
  -- 是否打开netrw
  if t.netrwWin then
    local curWin = vim.api.nvim_get_current_win()
    -- 是否已经在目录树窗口，是则关闭目录树，否则什么都用做
    if (curWin == t.netrwWin) then
      vim.api.nvim_win_close(curWin, true)
    else
      vim.api.nvim_set_current_win(t.netrwWin)
    end
  else
    -- 没有netrw窗口，则打开并保存winid
    cmd('1wincmd w')
    cmd('Lexplore ' .. fn.expand('%:p:h'))
  end
end, { silent = true })

vim.api.nvim_create_autocmd('WinNew', {
  callback = function()
    vim.defer_fn(function()
      if vim.o.filetype == 'netrw' then
        t.netrwWin = vim.api.nvim_get_current_win()
      end
    end, 0)
  end,
})
vim.api.nvim_create_autocmd('WinClosed', {
  callback = function()
    if vim.o.filetype == 'netrw' then
      t.netrwWin = nil
    end
  end,
})

o.splitright = true

cmd('autocmd filetype netrw call v:lua.Netrw_mappings()')
function Netrw_mappings()
  local buf = fn.bufnr('%')
  map('n', 'f', function()
    -- Split file
    local fn = GetCursorFile()
    cmd(string.format('silent vs %s/%s', b.netrw_curdir, fn))
    cmd('redraw!')
  end, {}, buf)
  map('n', '(', function()
    -- Create file
    local fn = vim.ui.input({
      prompt = 'Please enter filename: '
    }, function(fn)
      if fn then
        cmd(string.format('silent vs %s/%s', b.netrw_curdir, fn))
      end
    end)
  end, {}, buf)
  if vim.api.nvim_win_get_config(0).relative == '' then
    cmd('vertical res 20')
  end
end

function GetCursorFile()
  return string.gsub(trim(fn.getline('.')), '%*', '')
end
