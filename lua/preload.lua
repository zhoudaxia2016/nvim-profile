vim.pack.add({
  -- base
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim.git' },
  { src = 'https://github.com/shaunsingh/nord.nvim.git' },
  { src = 'https://github.com/windwp/nvim-autopairs.git' },
  -- official
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter.git', version = 'e5c8398e449281' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-refactor.git' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git' },
  { src = 'https://github.com/neovim/nvim-lspconfig.git', version = 'a2bd1cf' },
  -- dev
  { src = 'https://github.com/nvim-lua/plenary.nvim.git' },
})
