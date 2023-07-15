local Job = require'plenary.job'
local gitsign = ''

function GetStatuslineGitsign()
  return gitsign .. ' '
end

function StatuslineGitSign()
  Job:new({
    command = 'git',
    args = { 'diff', '--shortstat', 'HEAD', vim.fn.expand('%') },
    on_exit = function(j, return_val)
      local result = j:result()
      if return_val == 0 and result[1] ~= nil then
        local s = {}
        local addCount = string.match(result[1], '(%d+)%s+%w+%(%+%)')
        if addCount then
          table.insert(s, '++ ' .. addCount)
        end
        local deleteCount = string.match(result[1], '(%d+)%s+%w+%(%-%)')
        if deleteCount then
          table.insert(s, ' ' .. deleteCount)
        end
        gitsign = table.concat(s, ' ')
      else
        gitsign = ''
      end
    end,
  }):start()
end

vim.cmd[[au BufEnter,BufWritePost * call v:lua.StatuslineGitSign()]]

return function()
  return gitsign
end
