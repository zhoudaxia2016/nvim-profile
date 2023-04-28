local api = vim.api
local ns = api.nvim_create_namespace('gitlen')
local jobstart = require'util.jobstart'
local debounce = require'util.debounce'
local util = require('util')
local currentFileName
local currentLineNum
vim.cmd[[ hi GitBlameLen guifg=#616E88]]

local function starts(String, Start)
   return string.sub(String, 1, string.len(Start)) == Start
end
local makeExtmarkOptions = function(text)
  return {virt_text_pos = 'eol', virt_text = {{text, 'GitBlameLen'}}, hl_mode = 'combine'}
end

local function setBlameMsg(useFloat)
  if util.isSpecialBuf() then
    return
  end
  local lineNum = unpack(api.nvim_win_get_cursor(0))
  local fileName = vim.fn.expand('%:p')
  if lineNum == currentLineNum and fileName == currentFileName then
    return
  end
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  if pcall(api.nvim_buf_get_extmarks, 0, ns, lineNum, lineNum, {}) == false then
    local cmd = 'git blame ' .. vim.fn.expand('%') .. ' -L' .. lineNum .. ',' .. lineNum
    jobstart(cmd,
      function(msg)
        msg = util.trim(msg)
        if starts(msg, '00000000') then
          api.nvim_buf_set_extmark(0, ns, lineNum - 1, -1, makeExtmarkOptions('Not commit yet'))
        else
          local commitId = string.match(msg, "^%^?(%w+)")
          cmd = 'git log ' .. commitId .. " --pretty=format:'<%an>%ar->%h %s' | awk 'NR==1 {print; exit}'"
          jobstart(cmd,
            function(m)
              m = util.trim(m)
              if useFloat then
                vim.lsp.util.open_floating_preview({m}, '', {border = 'single'})
              else
                api.nvim_buf_set_extmark(0, ns, lineNum - 1, -1, makeExtmarkOptions(m))
              end
            end)
        end
      end
    )
  end
end
DebounceSetBlmeMsg = debounce(setBlameMsg, 1200)

jobstart('git rev-parse --is-inside-work-tree', function(isGitWorkTree)
  isGitWorkTree = util.trim(isGitWorkTree)
  if isGitWorkTree == 'true' then
    vim.cmd[[ au CursorHold * call v:lua.DebounceSetBlmeMsg() ]]
  end
end)

vim.keymap.set('n', '<leader>b', function()
  setBlameMsg(true)
end, {})
