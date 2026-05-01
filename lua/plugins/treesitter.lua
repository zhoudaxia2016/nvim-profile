local langs = {
  "javascript",
  "typescript",
  "tsx",
  "lua",
  "json",
  "jsonc",
  "query",
  "comment",
  "scheme",
  "markdown",
  "markdown_inline",
  "toml",
  "rust",
  "go",
  "c",
  "cpp",
  "git_config",
  "kotlin",
  "java",
}

local treesitter = require('nvim-treesitter')

local installed = {}
for _, lang in ipairs(treesitter.get_installed()) do
  installed[lang] = true
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.o.filetype)
    if not vim.tbl_contains(langs, lang) then
      return
    end

    if not installed[lang] then
      treesitter.install({ lang })
      return
    end

    if installed[lang] then
      vim.treesitter.start(args.buf, lang)
    end
  end
})
