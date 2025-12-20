vim.o.number = true
vim.o.relativenumber = true
vim.pack.add({
  { src = 'https://github.com/shaunsingh/nord.nvim.git' },
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  callback = function(args)
    vim.treesitter.start(args.buf, vim.treesitter.language.get_lang(vim.o.filetype))
    vim.g.nord_borders = true
    vim.g.nord_italic = false
    require('nord').set()
  end,
})

