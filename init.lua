local opt = vim.opt
local cmd = vim.cmd
local o = vim.o

vim.g.workspace = require('lspconfig.util').root_pattern('package.json', '.git')(vim.fn.getcwd()) or vim.fn.getcwd()

vim.o.packpath = o.runtimepath
vim.g.mapleader = ' '

vim.g.nord_borders = true
vim.g.nord_italic = false
require('nord').set()

require 'base-config'
require 'plugin-config'
require 'self-plugin'
local userConfig = vim.env.HOME .. '/.config/nvim/projects-config/user.lua'
if vim.fn.filereadable(userConfig) == 1 then
  vim.cmd('luafile ' .. userConfig)
end
