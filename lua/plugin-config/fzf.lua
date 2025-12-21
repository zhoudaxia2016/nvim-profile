local fzfBuiltins = require('self-plugin.fzf.builtin')
local getRoot = require('util').getRoot

---@param lhs string
---@param rhs string|function
---@param opts? vim.keymap.set.Opts
local function nmap(lhs, rhs, opts)
  vim.keymap.set('n', lhs, rhs, vim.tbl_extend('force', {buffer = true}, opts))
end

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    local ignore_fts = {'qf'}
    if vim.tbl_contains(ignore_fts, vim.o.filetype) then
      return
    end
    nmap('<cr>E', function()
      fzfBuiltins.findFile(vim.fn.getcwd())
    end, {desc = 'Search files in current directory'})
    nmap('<cr>e', function()
      fzfBuiltins.findFile(getRoot())
    end, {desc = 'Search files in current projects'})

    nmap('<cr>F', function()
      fzfBuiltins.rgSearch(vim.fn.getcwd())
    end, {desc = 'Search with rg in current directory'})
    nmap('<cr>f', function()
      fzfBuiltins.rgSearch(getRoot())
    end, {desc = 'Search with rg in current projects'})
    nmap('<cr><m-f>', function()
      vim.ui.input({ prompt = 'Enter ripgrep options: '}, function(input)
        if input == nil then
          return
        end
        fzfBuiltins.rgSearch(getRoot(), input)
      end)
    end, {desc = 'Search with rg and options'})

    nmap('<c-f>l', function()
      fzfBuiltins.searchLines()
    end, {desc = 'Search lines in current buffer'})

    nmap('<c-f>r', function()
      fzfBuiltins.oldFiles()
    end, {desc = 'Show old files'})

    nmap('<cr>b', function()
      fzfBuiltins.buffers()
    end, {desc = 'Show all buffers and jump to'})

    nmap('<cr>c', function()
      fzfBuiltins.clearBuffer()
    end, {desc = 'Show all buffers and clear'})

    nmap('<cr>j', function()
      fzfBuiltins.jumps()
    end, {desc = 'Show jumps'})

    nmap('<cr>m', function()
      fzfBuiltins.changes()
    end, {desc = 'Show changes'})

    nmap('<cr>a', function()
      fzfBuiltins.nvimApis()
    end, {desc = 'Show nvim apis'})

    nmap('<cr>z', function()
      fzfBuiltins.z()
    end, {desc = 'Show directorys recently visited'})
  end
})

vim.api.nvim_create_autocmd('VimEnter', {
  pattern = '*',
  callback = function()
    -- TODO: 因为参数是[nvim, --embed]，所以长度为2。需优化判断
    if #vim.v.argv == 2 then
      fzfBuiltins.oldFiles()
    end
  end
})

vim.api.nvim_create_user_command('FzfKeymaps', function()
  fzfBuiltins.keymaps()
end, {desc = 'Show all keymaps'})
