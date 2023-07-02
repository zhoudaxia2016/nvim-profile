local M = {}
M.file = function(params)
  local fn = params.fn
  local row = params.row
  local col = params.col
  local selection = params.selection
  local ns = params.ns
  local hlCol = params.hlCol
  local hlRow = params.hlRow
  local currentFn = vim.fn.expand('%:p')
  local buf = params.buf
  if fn and fn ~= currentFn then
    vim.cmd('edit ' .. fn)
  end
  if buf and vim.api.nvim_buf_get_name(buf) ~= currentFn then
    vim.cmd('b ' .. buf)
  end
  if row then
    vim.fn.cursor({row, col})
  end
  vim.cmd('normal z.')
  if ns then
    if hlCol then
      vim.highlight.range(0, ns, 'Todo', {row, col}, {row, col + 1}, {priority = 9999})
    end
    if selection then
      local startRange = selection.startRange
      local endRange = selection.endRange
      vim.highlight.range(0, ns, 'Todo', {startRange.line, startRange.character}, {endRange.line, endRange.character}, {priority = 9999})
    end
    if hlRow then
      vim.highlight.range(0, ns, 'CursorLine', {row, 0}, {row, 200}, {priority = 9999})
    end
  end
  vim.wo.winbar = fn
end

return M
