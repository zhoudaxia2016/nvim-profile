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
end, {desc = 'Nvim Help'})

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
vim.keymap.set('i', '<Tab>', cleverTab, {expr = true, desc = 'Clever Tab'})
vim.opt.cpt:append('k')
vim.opt.cpt:remove('t')

map('n', '<F2>', ':set hls!<cr>', {desc = 'Toggle highlight'})

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
    vim.keymap.set('n', '<tab>', enterFn, {buffer = true})
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

vim.keymap.set('n', '<A-LeftMouse>', function()
  local pos = vim.fn.getmousepos()
  if pos.screenrow >= vim.o.lines - 1 then
    return '<A-LeftMouse>'
  end
  return '<c-o>'
end, {expr = true, remap = true})
vim.keymap.set('n', '<2-LeftMouse>', 'yiw', {desc = 'Copy word at cursor'})
-- TODO bugfix 有时点击也会触发Drag，导致误触发复制
-- 应该是neovim bug？还是鼠标事件理解有误？
local isDrag = false
vim.keymap.set('n', '<LeftDrag>', function()
  isDrag = true
  return ''
end, {expr = true, remap = true, desc = 'Drag copy start'})
vim.keymap.set('n', '<LeftRelease>', function()
  local key = isDrag and '<LeftRelease>y' or '<LeftRelease>'
  isDrag = false
  return key
end, {expr = true, desc = 'Drag copy end'})
