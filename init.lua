local opt = vim.opt
local cmd = vim.cmd
local o = vim.o

opt.runtimepath:prepend('~/.nvim')
opt.runtimepath:append('~/.nvim/after')
vim.o.packpath = o.runtimepath
vim.g.mapleader = ' '
cmd[[
  filetype indent on
  filetype plugin on
  syntax on
  colors nord
]]

require 'base-config'
require 'plugin-config'
require 'self-plugin'
cmd[[au BufEnter /*wpsweb*.{ts,tsx,js} setl shiftwidth=4]]
