-- directory browser settings (builtin neovim directory browser)
local map = function(k, t)
  vim.keymap.set('n', k, t, { buffer = true })
end

-- navigation: focus right window
map('<c-l>', '<c-w><c-l>')
-- open entry to the right of directory
map('f', function()
  local dir = vim.api.nvim_buf_get_name(0)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
  if line then
    local path = dir .. '/' .. line:gsub('/$', '')
    local dir_win = vim.api.nvim_get_current_win()
    vim.cmd('wincmd l')
    local split = vim.api.nvim_get_current_win() == dir_win and 'rightbelow vs' or 'leftabove vs'
    vim.cmd(split .. ' ' .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_width(dir_win, 20)
  end
end, { desc = 'Open after directory' })
-- create file to the right of directory
map('(', function()
  local dir = vim.api.nvim_buf_get_name(0)
  vim.ui.input({ prompt = 'Please enter filename: ' }, function(fn)
    if fn then
      local dir_win = vim.api.nvim_get_current_win()
      vim.cmd('wincmd l')
      local split = vim.api.nvim_get_current_win() == dir_win and 'rightbelow vs' or 'leftabove vs'
      vim.cmd(split .. ' ' .. vim.fn.fnameescape(dir .. '/' .. fn))
      vim.api.nvim_win_set_width(dir_win, 20)
    end
  end)
end, { desc = 'Create file after directory' })

-- buffer options and window sizing
vim.opt_local.winfixwidth = true
vim.opt_local.number = false
vim.opt_local.relativenumber = true
vim.opt_local.wrap = true

-- initial resize when first displayed
vim.api.nvim_create_autocmd('BufWinEnter', {
  buffer = 0,
  callback = function()
    if vim.api.nvim_win_get_config(0).relative == '' then
      vim.cmd('vertical res 20')
    end
  end,
})
