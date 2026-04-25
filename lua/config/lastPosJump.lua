local group = vim.api.nvim_create_augroup('lastPosJump', {})
local function autocmd()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    group = group,
    callback = function()
      if vim.o.filetype:match('commit') == nil then
        local l = vim.fn.line("'\"")
        if l >= 1 and l <= vim.fn.line('$') then
          vim.cmd('normal! g`"')
        else
          vim.cmd('normal! G')
        end
      end
    end,
    once = true
  })
end
autocmd()

local M = {}
M.clear = function()
  vim.api.nvim_clear_autocmds({group = group})
end
M.autocmd = autocmd
return M
