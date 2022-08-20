local map = require'util'.map
map('n', '<leader><leader>', ':call v:lua.OpenHelpFile()<cr>')
function OpenHelpFile()
  vim.ui.input({
    prompt = 'Please input the help file name: ',
    completion = 'help'
  }, function(input)
    if input then
      vim.cmd('help ' .. input)
    end
  end)
end

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

map('n', '<c-e>', '<c-v>')
map('n', ';', ':', { silent = false })

map('c', '<m-l>', '<C-f>a<Tab>', { noremap = false })
