require('preload')
vim.g.workspace = require('lspconfig.util').root_pattern('package.json', '.git')(vim.fn.getcwd()) or vim.fn.getcwd()

vim.g.nord_borders = true
vim.g.nord_italic = false
require('nord').set()
if (vim.env.clean) then
  require 'clean'
  return
end

vim.g.mapleader = ' '
require 'config'
require 'plugins'
require 'features'

local last
vim.api.nvim_create_autocmd('DirChanged', {
  callback = function(ev)
    if ev.file == last then return end
    last = ev.file
    vim.schedule(function()
      vim.fn.chansend(vim.v.stderr,
        ('\027]7;file://%s%s\007'):format(vim.fn.hostname(), ev.file))
    end)
  end,
})

require('vim._core.ui2').enable({
  enable = true,
  msg = {
    target = 'cmd',
    timeout = 4000,
  },
})
