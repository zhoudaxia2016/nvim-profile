-- directory browser settings (builtin neovim directory browser)
local map = function(k, t)
  vim.keymap.set('n', k, t, { buffer = true })
end

-- navigation: focus right window
map('<c-l>', '<c-w><c-l>')

-- entry under the cursor; the builtin browser encodes newlines in filenames
-- as NUL and appends '/' to directories. Returns nil on an empty line.
local function get_entry()
  local line = vim.api.nvim_get_current_line()
  if line == '' then
    return nil
  end
  if line:sub(-1) == '/' then
    line = line:sub(1, -2)
  end
  if line == '' then
    return nil
  end
  return line:gsub('%z', '\n')
end

-- full path of the entry under the cursor, or nil
local function entry_path()
  local entry = get_entry()
  if entry then
    return vim.fs.joinpath(vim.api.nvim_buf_get_name(0), entry)
  end
end

-- open entry to the right of directory
map('f', function()
  local path = entry_path()
  if path then
    local dir_win = vim.api.nvim_get_current_win()
    vim.cmd('wincmd l')
    local split = vim.api.nvim_get_current_win() == dir_win and 'rightbelow vs' or 'leftabove vs'
    vim.cmd(split .. ' ' .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_width(dir_win, 20)
  end
end, { desc = 'Open after directory' })
-- open entry in a new tab
map('t', function()
  local path = entry_path()
  if path then
    vim.cmd('tabnew ' .. vim.fn.fnameescape(path))
  end
end, { desc = 'Open file in new tab' })
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
