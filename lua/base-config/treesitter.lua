local opt = vim.opt

opt.foldopen:append('jump')
opt.foldopen:append('search')
opt.foldopen:append('hor')

vim.o.foldtext = ''
vim.opt.foldmethod = "expr"
vim.o.foldlevel = 1
vim.o.foldminlines = 16

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    vim.wo[0][0].foldmethod = 'expr'
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
})
