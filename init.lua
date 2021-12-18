local opt = vim.opt
local cmd = vim.cmd
local o = vim.o

opt.runtimepath:prepend('~/.nvim')
opt.runtimepath:append('~/.nvim/after')
vim.o.packpath = o.runtimepath
cmd[[source ~/.vimrc]]

require 'base-config'
require 'plugin-config'
require 'self-plugin'
