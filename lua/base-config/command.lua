local installedParsers = require('nvim-treesitter.info').installed_parsers()
vim.api.nvim_create_user_command('QueryEditor', function(cmd)
  vim.treesitter.query.edit(cmd.fargs[1])
end, { desc = 'Edit treesitter query', nargs = '?', complete = function(args)
    return vim.tbl_filter(function(parser)
      return parser:find('^' .. args) ~= nil
    end, installedParsers)
  end
})
local autoSaveAutoCmdId
vim.api.nvim_create_user_command('ToggleAutoSave', function()
  if autoSaveAutoCmdId then
    vim.api.nvim_del_autocmd(autoSaveAutoCmdId)
    autoSaveAutoCmdId = nil
    vim.notify('AutoSave Mode is closed!')
  else
    autoSaveAutoCmdId = vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
      pattern = { "*" },
      command = "silent! w",
      nested = true,
    })
    vim.notify('AutoSave Mode is opened!')
  end
end, {})
