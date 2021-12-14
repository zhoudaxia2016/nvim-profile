local jobstart = require('util.jobstart')
local util = require('util')
function CopyToSystem()
  local temp = vim.fn.tempname()
  local fd = io.open(temp, 'w')
  io.output(fd)
  io.write(vim.fn.getreg('"'))
  io.close(fd)
  jobstart('clip.exe < ' .. temp)
end
vim.api.nvim_set_keymap('n', '<m-o>', '<Cmd>call v:lua.CopyToSystem()<cr>', { silent = true })

function ConfigFold()
  vim.defer_fn(function()
    if util.isSpecialBuf() then
      return
    end
    if vim.fn.line('$') > 80 then
      vim.o.foldmethod = 'indent'
      vim.o.foldlevel = 3
      vim.o.foldopen = 'jump'
    else
      vim.o.foldenable = false
    end
  end, 0)
end

vim.cmd[[au BufAdd * call v:lua.ConfigFold()]]

vim.cmd[[hi TSConstructor guifg=#bbded6]]
vim.cmd[[hi TSConditional guifg=#ecd6c7]]
vim.cmd[[hi TSTypeBuiltin guifg=#96C0CE]]
vim.cmd[[hi TSVariableBuiltin guifg=#518f8b]]
vim.cmd[[hi TSStringRegex guifg=#B9A7C2]]
require'nvim-treesitter.configs'.setup {
  ensure_installed = {"javascript", "typescript", "tsx"}, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
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
}
