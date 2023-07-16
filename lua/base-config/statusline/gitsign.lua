local gitsign = ''

function GetStatuslineGitsign()
  return gitsign .. ' '
end

function StatuslineGitSign()
  vim.system({'git', 'diff', '--shortstat', 'HEAD', vim.fn.expand('%')}, {text = true}, function(result)
    local stdout = result.stdout
    if result.signal == 0 and stdout then
      local s = {}
      local addCount = string.match(stdout, '(%d+)%s+%w+%(%+%)')
      if addCount then
        table.insert(s, '++ ' .. addCount)
      end
      local deleteCount = string.match(stdout, '(%d+)%s+%w+%(%-%)')
      if deleteCount then
        table.insert(s, ' ' .. deleteCount)
      end
      gitsign = table.concat(s, ' ')
    else
      gitsign = ''
    end
  end)
end

vim.cmd[[au BufEnter,BufWritePost * call v:lua.StatuslineGitSign()]]

return function()
  return gitsign
end
