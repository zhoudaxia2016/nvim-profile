local M = {}
M.file = function(params)
  local fn = params.fn
  local row = params.row
  local col = params.col
  local selection = params.selection
  local ns = params.ns
  local hlCol = params.hlCol
  vim.cmd('edit ' .. fn)
  vim.fn.cursor({row, col})
  vim.cmd('redraw')
  if hlCol and ns then
    vim.highlight.range(0, ns, 'Todo', {row, col}, {row, col + 1}, {priority = 9999})
  end
  if selection and ns then
    local startRange = selection.startRange
    local endRange = selection.endRange
    vim.highlight.range(0, ns, 'Todo', {startRange.line, startRange.character}, {endRange.line, endRange.character}, {priority = 9999})
  end
  vim.wo.winbar = fn
end

return M
