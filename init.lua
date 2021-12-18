local opt = vim.opt
local cmd = vim.cmd
local o = vim.o

opt.runtimepath:prepend('~/.nvim')
opt.runtimepath:append('~/.nvim/after')
vim.o.packpath = o.runtimepath
cmd[[source ~/.vimrc]]

require 'translate'
require 'git'
require 'popup'
require 'chore'
require 'easy-motion'
require 'lsp'

opt.inccommand = 'split'
cmd[[
  augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank { higroup='DiffText', timeout=700 }
  augroup END
]]

require 'gotofile'
require 'treesitter'
require 'nvim-luadev'
require 'popfix-config'
