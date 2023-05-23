-- refer to https://github.com/whiteinge/diffconflicts
vim.api.nvim_create_user_command('MergeTool', function()
  vim.cmd[[
        silent execute "g/^=======\\r\\?$/,/^>>>>>>> /d"
        silent execute "g/^<<<<<<< /d"
        diffthis
        vsplit
        b REMOTE
        diffthis
  ]]
end, {})

vim.api.nvim_create_user_command('Diff', function(params)
  local args = params.args
  local tmpPatchFile = vim.fn.tempname()
  local cmd = 'git diff --no-color '
  if args == '' then
    cmd = cmd .. '-R '
  else
    cmd = cmd .. '..' .. args .. ' -- ' .. vim.fn.expand('%')
  end
  cmd = cmd .. ' > ' .. tmpPatchFile
  vim.fn.system(cmd)
  vim.cmd('silent vert diffpatch ' .. tmpPatchFile)
  vim.o.bufhidden = 'delete'
end, {nargs = '?'})
