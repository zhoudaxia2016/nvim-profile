local api = vim.api
local ns = api.nvim_create_namespace('gitlen')
local jobstart = require'util.jobstart'
local debounce = require'util.debounce'
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
        msg = string.gsub(msg, "^%s*(.-)%s*$", "%1")
        if starts(msg, '00000000') then
          api.nvim_buf_set_extmark(0, ns, lineNum - 1, -1, {virt_text_pos = 'eol', virt_text = {{'Not commit yet', 'GitBlameLen'}}})
        else
          local commitId = string.match(msg, "^%^?(%w+)")
          cmd = 'git log ' .. commitId .. " --pretty=format:'<%an>%ar->%h %s' | awk 'NR==1 {print; exit}'"
          jobstart(cmd,
            function(m)
              m = string.gsub(m, "^[%s]*(.-)%s*$", "%1")
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

vim.cmd[[ au CursorMoved * call v:lua.GitHandlerCursorMoved() ]]
