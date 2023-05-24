-- refer to https://github.com/whiteinge/diffconflicts

local beginMark = '^<<<<<<<'
local operatorMark = '^======='
local endMark = '^>>>>>>>'

vim.api.nvim_create_user_command('MergeTool', function()
  vim.cmd(string.format([[
        silent execute "g/%s\\r\\?$/,/%s /d"
        silent execute "g/%s /d"
        diffthis
        vsplit
        b REMOTE
        diffthis
  ]], operatorMark, endMark, beginMark))
end, {})

vim.api.nvim_create_user_command('Diff', function(params)
  local args = params.args
  local tmpPatchFile = vim.fn.tempname()
  local currentFile = vim.fn.expand('%')
  local cmd = 'git diff --no-color '
  if args == '' then
    cmd = cmd .. '-R ' .. currentFile
  else
    cmd = cmd .. '..' .. args .. ' -- ' .. currentFile
  end
  cmd = cmd .. ' > ' .. tmpPatchFile
  vim.fn.system(cmd)
  vim.cmd('silent vert diffpatch ' .. tmpPatchFile)
  vim.o.bufhidden = 'delete'
end, {
    nargs = '?',
    complete = function(leading)
      local branchs = vim.split(vim.trim(vim.fn.system("git for-each-ref --format='%(refname:short)' --sort=committerdate")), '%s+')
      branchs = vim.tbl_filter(function(v) return v:lower():match(leading:lower()) end, branchs)
      return branchs
    end
  })
