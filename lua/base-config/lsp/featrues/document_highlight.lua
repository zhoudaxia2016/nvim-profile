local documentHighlightResult
local documentHighlightHandler = vim.lsp.handlers['textDocument/documentHighlight']
vim.lsp.handlers['textDocument/documentHighlight'] = function(err, result, ctx, config)
  if not result then
    return
  end

  local start_line = vim.fn.line('w0') - 1
  local end_line = vim.fn.line('w$') - 1
  local n = 0
  for _, value in pairs(result) do
    local s = value.range.start.line
    local e = value.range['end'].line
    if s >= start_line and e <= end_line then
      n = n + 1
    end
  end
  documentHighlightResult = {}
  for k, v in pairs(result) do
    documentHighlightResult[k] = v
  end
  table.sort(documentHighlightResult, function(a, b)
    local start1 = a.range.start
    local start2 = b.range.start
    if start1.line - start2.line < 0 then
      return true
    end
    if start1.line - start2.line > 0 then
      return false
    end
    return (start1.character - start2.character) < 0
  end)
  documentHighlightHandler(err, result, ctx, config)
end

local ns = vim.api.nvim_create_namespace('lsp-feature-document_highlight')

local M = {}

M.goto_doc_hl_result = function(dir)
  if documentHighlightResult == nil then
    return
  end
  local cur_row = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local n = #documentHighlightResult
  local i = dir == 1 and 1 or n
  local search_index
  -- TODO: binary search
  while i <= n and i > 0 do
    local range = documentHighlightResult[i].range
    local col = range.start.character + 1
    local row = range.start.line + 1
    if dir == 1 then
      if row > cur_row or (row == cur_row and col > cur_col) then
        search_index = i
        break
      end
    else
      if row < cur_row or (row == cur_row and col > cur_col) then
        search_index = i
        break
      end
    end
    i = i + dir
  end
  if search_index == nil then
    search_index = dir == 1 and 1 or n
  end
  local start = documentHighlightResult[search_index].range.start
  vim.fn.cursor(start.line + 1, start.character + 1)
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  vim.defer_fn(function()
    vim.api.nvim_buf_set_extmark(0, ns, start.line, -1, {
      virt_text = {{("[%s/%s]"):format(search_index, n), 'Comment'}},
      hl_mode = 'combine',
      priority = 200,
    })
  end, 200)
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(0, ns, start.line, -1)
  end, 3000)
end

return M
