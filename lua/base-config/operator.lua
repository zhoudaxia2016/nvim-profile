OperatorFunc = nil
local utils = require "nvim-treesitter.ts_utils"
local pairs = {
  ['"'] = '"',
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  ['<'] = '>'
}
local prefix = '<leader>o'
local function newOperator(key, fn)
  vim.keymap.set({'n', 'v'}, prefix .. key, function()
    OperatorFunc = fn
    -- TODO use lua function: vim.o.operatorfunc = fn
    vim.o.operatorfunc = 'v:lua.OperatorFunc'
    return 'g@'
  end, { expr = true, silent = true, noremap = true })
end

local getLine = vim.fn.line
local getCol = vim.fn.col

newOperator('s', function()
  local parser = vim.treesitter.get_parser(0)
  local tstree = parser:parse()
  local startLine = getLine("'[") - 1
  local startCol = getCol("'[") - 1
  local stopLine = getLine("']") - 1
  local stopCol = getCol("']") - 1
  local node = tstree[1]:root():descendant_for_range(startLine, startCol, stopLine, stopCol)
  local fc = string.char(vim.fn.getchar())
  local lc = pairs[fc]
  if (lc == nil) then
    lc = fc
  end
  local range = utils.node_to_lsp_range(node)
  local edits = {
    { newText = fc .. vim.treesitter.get_node_text(node, 0) .. lc, range = range },
  }
  vim.lsp.util.apply_text_edits(edits, 0, 'utf-8')
end)

newOperator('b', function()
  local startLine = getLine("'[") - 1
  local stopLine = getLine("']") - 1
  local cmd = string.format('git log -L %d,%d:%s', startLine, stopLine, vim.fn.expand('%'))
  vim.print(vim.fn.system(cmd))
end)
