local opt = vim.opt
local cmd = vim.cmd
local o = vim.o
vim.g.nord_italic = false

vim.g.workspace = require('lspconfig.util').root_pattern('package.json', '.git')(vim.fn.getcwd()) or vim.fn.getcwd()

opt.runtimepath:prepend('~/.nvim')
opt.runtimepath:append('~/.nvim/after')
vim.o.packpath = o.runtimepath
vim.g.mapleader = ' '
vim.g.nord_borders = true
cmd[[
  filetype indent on
  filetype plugin on
  syntax on
  colors nord
]]

require 'base-config'
require 'plugin-config'
require 'self-plugin'
local userConfig = vim.env.HOME .. '/.config/nvim/projects-config/user.lua'
if vim.fn.filereadable(userConfig) == 1 then
  vim.cmd('luafile ' .. userConfig)
end
