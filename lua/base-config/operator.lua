OperatorFunc = nil
local jobstart = require('util.jobstart')
local utils = require "nvim-treesitter.ts_utils"
local function prefix(key)
  return "<m-q><m-" .. key .. ">"
end
local pairs = {
  ['"'] = '"',
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  ['<'] = '>'
}
local function newOperator(key, fn)
  vim.keymap.set({'n', 'v'}, key, function()
    OperatorFunc = fn
    -- TODO use lua function: vim.o.operatorfunc = fn
    vim.o.operatorfunc = 'v:lua.OperatorFunc'
    return 'g@'
  end, { expr = true, silent = true, noremap = true })
end

local function getRange()
  local start = vim.fn.line("'['")
  local stop = vim.fn.line("']'")
  return start, stop
end

newOperator('<m-u><m-w>', function()
  local getLine = vim.fn.line
  local getCol = vim.fn.col
  local parser = vim.treesitter.get_parser(0)
  local tstree = parser:parse()
  local startLine = getLine("'[") - 1
  local startCol = getCol("'[") - 1
  local stopLine = getLine("']") - 1
  local stopCol = getCol("']") - 1
  local node = tstree[1]:root():descendant_for_range(startLine, startCol, stopLine, stopCol)
  local parent = node:parent()
  local f = parent:child(0)
  local l = parent:child(parent:child_count() - 1)
  local fc = string.char(vim.fn.getchar())
  local lc = pairs[fc]
  if (lc == nil) then
    lc = fc
  end
  local frange = utils.node_to_lsp_range(f)
  local lrange = utils.node_to_lsp_range(l)
  local edits = {
    { newText = fc, range = frange },
    { newText = lc, range = lrange }
  }
  print(vim.inspect(edits))
  vim.lsp.util.apply_text_edits(edits, 0, 'utf-8')
end)
