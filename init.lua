local opt = vim.opt
local cmd = vim.cmd
local o = vim.o

opt.runtimepath:prepend('~/.nvim')
opt.runtimepath:append('~/.nvim/after')
vim.o.packpath = o.runtimepath
cmd[[source ~/.vimrc]]

opt.inccommand = 'split'
cmd[[
  augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank { higroup='DiffText', timeout=700 }
  augroup END
]]

require 'base-config'
require 'plugin-config'
require 'self-plugin'
