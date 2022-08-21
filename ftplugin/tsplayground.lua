local ts_utils = require('nvim-treesitter.ts_utils')
local api = vim.api
require('util').map('n', '<m-p>', function()
  local bufs = api.nvim_list_bufs()
  local startRow, startCol, endRow, endCol = ts_utils.get_node_range(ts_utils.get_node_at_cursor())
  for _, b in pairs(bufs) do
    if api.nvim_buf_get_option(b, 'filetype') == 'tsplayground' then
      vim.cmd('wincmd l')
      vim.cmd(string.format('/\\w* \\[%s, %s\\] - \\[%s, %s\\]', startRow, startCol, endRow, endCol))
    end
  end
end)
