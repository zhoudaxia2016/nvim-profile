vim.g.workspace = require('lspconfig.util').root_pattern('package.json', '.git')(vim.fn.getcwd()) or vim.fn.getcwd()

vim.g.nord_borders = true
vim.g.nord_italic = false
require('nord').set()

vim.g.mapleader = ' '
require 'base-config'
require 'plugin-config'
require 'self-plugin'

-- TODO: will be fixed after #21771 close
vim.cmd[[
autocmd DirChanged * call chansend(v:stderr, printf("\033]7;%s\033", v:event.cwd))
]]
