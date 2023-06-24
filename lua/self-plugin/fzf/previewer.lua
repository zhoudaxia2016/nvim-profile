local M = {}
M.file = function(params)
  local fn = params.fn
  local row = params.row
  local col = params.col
  local selection = params.selection
  local ns = params.ns
  local cmd = string.format('edit %s', fn)
  if row then
    cmd = string.format('edit +%s %s', row, fn)
    if col then
      cmd = cmd .. string.format(' | normal %sl', col)
    end
  end
  vim.cmd(cmd)
  if selection then
    local startRange = selection.startRange
    local endRange = selection.endRange
    vim.highlight.range(0, ns, 'Todo', {startRange.line, startRange.character}, {endRange.line, endRange.character}, {priority = 9999})
  end
  vim.wo.winbar = fn
end

return M
