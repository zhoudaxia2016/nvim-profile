vim.api.nvim_create_user_command('SearchColumn', function(opt)
  local args = opt.fargs[1]
  local col = vim.fn.col('.')
  vim.cmd(string.format('normal /%s', args))
end, {
  nargs = 1,
})
