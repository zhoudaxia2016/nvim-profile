local cmd = vim.cmd
cmd[[
  augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank { higroup='DiffText', timeout=700 }
  augroup END
]]
