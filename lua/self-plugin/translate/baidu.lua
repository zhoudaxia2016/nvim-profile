local config = vim.g.baiduApi
if (config == nil or config.appId == nil or config.appKey == nil) then
  vim.notify('[Translate] please config your appId and appKey...')
  return
end
local appId = config.appId
local appKey = config.appKey

local cmd, api, fn = vim.cmd, vim.api, vim.fn
local curl = require('plenary.curl')
local random = tostring(math.random(bit.rshift(1, 5)))
local uri = 'https://fanyi-api.baidu.com/api/trans/vip/translate'

cmd('hi Translate guifg=#bbded6 guibg=transparent')

local getField = function(word)
  local curtime = tostring(os.time())
  local salt = random .. curtime
  local hash = appId .. word .. salt .. appKey
  local sign = vim.fn.sha256(hash)
  return {
    q = word,
    from = 'auto',
    to = 'zh',
    signType = 'v3',
    appid = appId,
    salt = salt,
    sign = sign,
    action = 1,
  }
end

return function (word)
  local field = getField(word)
  curl.post(uri, {
    body = field,
    callback = function(output)
      local result = vim.json.decode(output.body)
      if (result == nil or result.trans_result == nil) then
        return
      end
      vim.schedule(function()
        local buf = api.nvim_create_buf(false, true)
        api.nvim_buf_set_lines(buf, 0, -1, true, {result.trans_result[1].dst})
        local id = api.nvim_open_win(buf, false, { style = 'minimal', relative = 'cursor', row = 1, col = 0, width = 10, height = 3, border = 'single' })
        api.nvim_set_option_value('winhl', 'Normal:Translate', {win = id})
        vim.api.nvim_create_autocmd({'CursorMoved', 'CmdLineEnter'}, {
          callback = function()
            if id and api.nvim_win_is_valid(id) then
              api.nvim_win_close(id, true)
            end
          end,
          once = true,
        })
      end)
    end
  })
end
