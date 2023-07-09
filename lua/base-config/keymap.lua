local map = require'util'.map
map('n', '<leader><leader>', function()
  vim.ui.input({
    prompt = 'Please input the help file name: ',
    completion = 'help'
  }, function(input)
    if input then
      vim.cmd('help ' .. input)
    end
  end)
end)

-- move around window
map('n', '<c-l>', '<c-w><c-l>')
map('n', '<c-h>', '<c-w><c-h>')
map('n', '<c-j>', '<c-w><c-j>')
map('n', '<c-k>', '<c-w><c-k>')
map('n', '<c-b>', '<c-w><c-b>')

map('n', '<leader>s', ':w !sudo tee %<cr>')

-- jump tab
map('n', '<leader>1', '1gt')
map('n', '<leader>2', '2gt')
map('n', '<leader>3', '3gt')
map('n', '<leader>4', '4gt')
map('n', '<leader>5', '5gt')

map('i', '<c-k>', '<c-x><c-k>')
map('i', '<c-l>', '<c-x><c-l>')
map('i', '<c-t>', '<c-x><c-t>')
map('i', '<c-f>', '<c-x><c-f>')
map('i', '<c-d>', '<c-x><c-d>')
map('i', '<c-o>', '<c-x><c-o>')
map('i', '<c-i>', '<c-x><c-i>')

map('n', '<c-e>', '<c-v>')
map('n', ';', ':', { silent = false })

map('c', '<m-l>', '<C-f>a<Tab>', { noremap = false })

local function cleverTab()
  local col = vim.fn.col('.')
  if col == 1 or vim.fn.getline('.'):sub(col-1, col-1):match('%s') then
    return "<Tab>"
  else
    return "<c-n>"
  end
end
vim.keymap.set('i', '<Tab>', cleverTab, {expr=true})
vim.opt.cpt:append('k')

map('n', '<F2>', ':set hls!<cr>')

local function patchEnter()
  local keymaps = vim.api.nvim_buf_get_keymap(0, 'n')
  local enterFn
  for _, item in pairs(keymaps) do
    if item.lhs == '<CR>' then
      enterFn = item.rhs or item.callback
      break
    end
  end
  if enterFn then
    vim.keymap.set('n', '<tab>', enterFn)
  end
end

-- Enter has been used as a prefix for other keymap.
-- But in some file, we map enter.
-- We need to use other key for this.
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'qf', 'query'},
  callback = function()
    if vim.o.filetype == 'query' then
      vim.defer_fn(patchEnter, 0)
    else
      patchEnter()
    end
  end
})

vim.keymap.set('n', '<A-LeftMouse>', '<c-o>')
vim.keymap.set('n', '<2-LeftMouse>', 'yiw')
vim.keymap.set('n', '<LeftDrag>', '<Nop>')
vim.keymap.set('n', '<LeftRelease>', '<LeftRelease>y')
