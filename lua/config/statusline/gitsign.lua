local gitsign = ''
local git = require('util.git')

local function getStatuslineGitsign()
  return gitsign .. ' '
end

local function updateStatuslineGitSign()
  local context = git.get_context(0)
  if context == nil then
    gitsign = ''
    return
  end

  local code, stdout = git.run(context, {
    'diff',
    '--shortstat',
    'HEAD',
    '--',
    context.relpath,
  })
  if code == 0 and stdout then
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
end

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
  callback = updateStatuslineGitSign,
})

return function()
  return getStatuslineGitsign():gsub('%s$', '')
end
