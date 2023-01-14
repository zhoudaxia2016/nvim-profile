vim.cmd[[au BufAdd * call v:lua.ConfigFold()]]

require'nvim-treesitter.configs'.setup {
  ensure_installed = {"javascript", "typescript", "tsx", "lua", "json", "query", "comment", "scheme", "markdown", "markdown_inline"}, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  sync_install = false, -- install languages synchronously (only applied to `ensure_installed`)
  highlight = {
    enable = true,              -- false will disable the whole extension
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
    custom_captures = {
      ["call_expression"] = "TSConditional"
    }
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "gnn",
      node_incremental = "n",
      scope_incremental = "m",
      node_decremental = "N",
    },
  },
  fold = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["ab"] = "@block.outer",
        ["ip"] = "@parameter.inner",
        ["ap"] = "@parameter.outer",
        ["io"] = "@pair.inner",
        ["ao"] = "@pair.outer",
        ["ij"] = "@jsxattr.value",
        ["aj"] = "@jsxattr.outer",
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
    }
  },
  refactor = {
    highlight_definitions = { enable = true },
    smart_rename = {
      enable = true,
      keymaps = {
        smart_rename = "grr",
      },
    },
    navigation = {
      enable = true,
      keymaps = {
        goto_definition = "gnd",
      },
    },
  },
  indent = {
    enable = true
  },
}
