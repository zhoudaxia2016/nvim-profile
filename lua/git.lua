local api = vim.api
local ns = api.nvim_create_namespace('gitlen')
local jobstart = require'util.jobstart'
local debounce = require'util.debounce'
local util = require('util')
vim.cmd[[ hi GitBlameLen guifg=#616E88 guibg=#3B4252]]
function starts(String, Start)
   return string.sub(String, 1, string.len(Start)) == Start
end
local function setBlameMsg()
  local lineNum = unpack(api.nvim_win_get_cursor(0))
  if pcall(api.nvim_buf_get_extmarks, 0, ns, lineNum, lineNum, {}) == false then
    local cmd = 'git blame ' .. vim.fn.expand('%') .. ' -L' .. lineNum .. ',' .. lineNum
    jobstart(cmd,
      function(msg)
        msg = util.trim(msg)
        if starts(msg, '00000000') then
          api.nvim_buf_set_extmark(0, ns, lineNum - 1, -1, {virt_text_pos = 'eol', virt_text = {{'Not commit yet', 'GitBlameLen'}}})
        else
          local commitId = string.match(msg, "^%^?(%w+)")
          cmd = 'git log ' .. commitId .. " --pretty=format:'<%an>%ar->%h %s' | awk 'NR==1 {print; exit}'"
          jobstart(cmd,
            function(m)
              m = util.trim(m)
              api.nvim_buf_set_extmark(0, ns, lineNum - 1, -1, {virt_text_pos = 'eol', virt_text = {{m, 'GitBlameLen'}}})
            end)
        end
      end
    )
  end
end
local debounceSetBlmeMsg = debounce(setBlameMsg, 1200)
function GitHandlerCursorMoved()
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  debounceSetBlmeMsg()
end

jobstart('git rev-parse --is-inside-work-tree', function(isGitWorkTree)
  isGitWorkTree = util.trim(isGitWorkTree)
  if isGitWorkTree == 'true' then
    vim.cmd[[ au CursorMoved * call v:lua.GitHandlerCursorMoved() ]]
  end
end)
