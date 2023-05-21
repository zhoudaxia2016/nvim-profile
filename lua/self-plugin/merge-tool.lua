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
