local lastCmdline
local lastPos
local completed

local function cmdComplete(forward)
  if vim.fn.wildmenumode() == 1 then
    if forward then
      return '<c-n>'
    else
      return '<c-p>'
    end
  end

  if lastCmdline == nil then
    lastCmdline = vim.fn.getcmdline()
    lastPos = 0
  end

  local triggerStart, triggerEnd = vim.regex('\\k\\+$'):match_str(lastCmdline)
  local trigger = string.sub(lastCmdline, triggerStart + 1, triggerEnd)
  if trigger == '' then
    return
  end
  local searchStr = '\\<' .. trigger .. '\\k\\+'
  if forward == false then
    searchStr = searchStr .. '\\(' .. searchStr .. '\\)\\@!'
  end
  local searchPattern = vim.regex(searchStr)
  local content = vim.fn.join(vim.api.nvim_buf_get_text(0, 0, 0, -1, -1, {}), '\n')
  if forward then
    content = string.sub(content, lastPos, -1)
  else
    content = string.sub(content, 0, lastPos - 1)
  end
  local i, j = searchPattern:match_str(content)
  if i then
    completed = true
    local currentCmdline = vim.fn.getcmdline()
    local s, e = vim.regex('\\k\\+$'):match_str(currentCmdline)
    local removeKeycodes = string.rep('<c-h>', e - s)
    if forward then
      lastPos = lastPos + j + 1
    else
      lastPos = i - 1
    end
    vim.defer_fn(function()
      completed = false
    end, 0)
    return removeKeycodes .. string.sub(content, i + 1, j)
  end
  return ''
end

vim.api.nvim_create_autocmd('CmdlineChanged', {
  callback = function()
    if completed ~= true then
      lastCmdline = nil
    end
  end
})

vim.keymap.set('c', '<c-n>', function()
  return cmdComplete(true)
end, {expr = true})

vim.keymap.set('c', '<c-p>', function()
  return cmdComplete(false)
end, {expr = true})
