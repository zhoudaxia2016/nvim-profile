local langs = {"javascript", "typescript", "tsx", "lua", "json", "jsonc", "query", "comment", "scheme", "markdown", "markdown_inline", "toml", "rust", "go", "c", "cpp", "git_config", "kotlin", "java"}

require'nvim-treesitter'.install(langs)
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.o.filetype)
    if vim.tbl_contains(langs, lang) then
      vim.treesitter.start(args.buf, lang)
    end
  end
})
