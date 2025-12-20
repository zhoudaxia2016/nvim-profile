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
local uri = 'https://tmt.tencentcloudapi.com'

local getBody = function(text)
  return {
    SourceText = text,
    Source = 'auto',
    Target = 'zh',
    ProjectId = 0,
  }
end

local getHeaders = function()
  return {
    ['X-TC-Action'] = 'TextTranslate',
  }
end

return function(text)
  local body = getBody(text)
  local headers = getHeaders()
end
