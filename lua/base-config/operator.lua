OperatorFunc = nil
local pair_chars = {
  ['"'] = '"',
  ['('] = ')',
  ['['] = ']',
  ['{'] = '}',
  ['<'] = '>',
  ["'"] = "'",
}

local descPrefix = '[Operator]: '
local prefix = '<leader>o'
local function newOperator(key, fn, desc)
  vim.keymap.set({'n', 'v'}, prefix .. key, function()
    OperatorFunc = fn
    -- TODO use lua function: vim.o.operatorfunc = fn
    vim.o.operatorfunc = 'v:lua.OperatorFunc'
    return 'g@'
  end, { expr = true, silent = true, noremap = true, desc = descPrefix .. (desc or '') })
end

local getLine = vim.fn.line
local getCol = vim.fn.col

local function matchPair(str)
  local first = str:sub(1, 1)
  local last = str:sub(-1)
  return pair_chars[first] == last
end

vim.keymap.set('n', '<leader>oO', function()
  local node = vim.treesitter.get_node()
  local isPair = false
  if node == nil then
    return
  end
  while (node) do
    local text = vim.treesitter.get_node_text(node, 0)
    if matchPair(text) then
      isPair = true
      break
    end
    node = node:parent()
  end
  if isPair then
    local startRow, startCol, endRow, endCol = vim.treesitter.get_node_range(node)
    local text = vim.treesitter.get_node_text(node, 0)
    local edits = {
      {
        newText = text:sub(2, #text - 1),
        range = {
          start = {line = startRow, character = startCol},
          ['end'] = {line = endRow, character = endCol},
        }
      }
    }
vim.lsp.util.apply_text_edits(edits, vim.api.nvim_get_current_buf(), 'utf-8')
  end
end, {desc = descPrefix .. 'Surround delete'})

local function surround(multi)
  multi = multi or false
  local startLine = getLine("'[") - 1
  local startCol = getCol("'[") - 1
  local stopLine = getLine("']") - 1
  local stopCol = getCol("']") - 1

  local c = vim.fn.getcharstr()
  local lc = c
  if multi then
    while(true) do
      c = vim.fn.getcharstr()
      if c == '\r' then
        break
      end
      lc = lc .. c
    end
  end

  local rc = pairs[lc]
  if (rc == nil) then
    rc = lc
  end
  local leftRange = {
    start = { line = startLine, character = startCol},
    ['end'] = { line = startLine, character = startCol}
  }
  local rightRange = {
    start = { line = stopLine, character = stopCol + 1},
    ['end'] = { line = stopLine, character = stopCol + 1}
  }
  local edits = {
    { newText = lc, range = leftRange },
    { newText = rc, range = rightRange },
  }
  vim.lsp.util.apply_text_edits(edits, 0, 'utf-8')
end

newOperator('o', function()
  surround()
end, 'Surround insert a char')
newOperator('p', function()
  surround(true)
end, 'Surround insert a string, enter <cr> to finish')

newOperator('b', function()
  local startLine = getLine("'[")
  local stopLine = getLine("']")
  local cmd = string.format('tmux new-window "git log -L %d,%d:%s | less -R"', startLine, stopLine, vim.fn.expand('%'))
  vim.fn.system(cmd)
end, 'Git blame')

newOperator('t', function()
  local _, startRow, startCol = unpack(vim.fn.getpos("'["))
  local _, endRow, endCol = unpack(vim.fn.getpos("']"))
  local word = vim.api.nvim_buf_get_text(0, startRow - 1, startCol - 1, endRow - 1, endCol, {})[1]
  require('self-plugin.translate')(word)
end, 'Translate')
