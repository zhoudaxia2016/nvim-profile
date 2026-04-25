local M = require('util')

local _utils = {
  debounce = true
}

vim.tbl_extend('force', M, {
  debounce = nil, ---@module 'util.debounce'
})

setmetatable(M, {
  __index = function(t, key)
    if _utils[key] then
      t[key] = require('util.' .. key)
      return t[key]
    end
  end,
})

_G.utils = M
