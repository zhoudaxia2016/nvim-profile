local installedParsers = require('nvim-treesitter.info').installed_parsers()
vim.api.nvim_create_user_command('QueryEditor', function(cmd)
  vim.treesitter.query.edit(cmd.fargs[1])
end, { desc = 'Edit treesitter query', nargs = '?', complete = function(args)
    return vim.tbl_filter(function(parser)
      return parser:find('^' .. args) ~= nil
    end, installedParsers)
  end
})
