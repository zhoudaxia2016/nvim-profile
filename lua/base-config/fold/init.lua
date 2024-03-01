require('base-config.fold.nvim-treesitter-fold')
local util = require('util')
local opt = vim.opt

opt.foldopen:append('jump')
opt.foldopen:append('search')
opt.foldopen:append('hor')

vim.o.foldtext = ''
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.require('base-config.fold.nvim-treesitter-fold')()"
vim.o.foldlevel = 1
vim.o.foldminlines = 16

vim.api.nvim_create_autocmd('FileType', {
  once = true,
  callback = function()
    vim.defer_fn(function()
      if util.isSpecialBuf() then
        return
      end
      vim.wo.foldenable = true
    end, 0)
  end
})

vim.o.mousemoveevent = true

local ns = vim.api.nvim_create_namespace('fold')
vim.keymap.set({'n', 'i'}, '<MouseMove>', function()
  local pos = vim.fn.getmousepos()
  if pos.line == 0 then
    return
  end
  if vim.fn.foldclosed(pos.line) == -1 then
    return
  end
  local buf = vim.api.nvim_win_get_buf(pos.winid)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(buf, ns, pos.line - 1, pos.column - 1, {
    virt_text = {{'▶', 'number'}},
    virt_text_win_col = 0,
  })
end)

vim.keymap.set({'n', 'i'}, '<LeftMouse>', function()
  local pos = vim.fn.getmousepos()
  if pos.line == 0 then
    return
  end
  if vim.fn.foldclosed(pos.line) == -1 then
    return
  end
  local buf = vim.api.nvim_win_get_buf(pos.winid)
  local start = {pos.line - 1, pos.column - 1}
  local m = vim.api.nvim_buf_get_extmarks(buf, ns, start, start, {})
  if m == nil then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(buf, ns, pos.line - 1, pos.column - 1, {
    virt_text = {{'▼', 'number'}},
    virt_text_win_col = 0,
  })
end)
