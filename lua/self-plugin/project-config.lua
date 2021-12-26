local configDir = vim.fn.stdpath('config') .. '/projects-config/'
local util = require('lspconfig.util')

local function getConfigFile()
  local root = util.find_package_json_ancestor(vim.fn.getcwd())
  if root == nil then
    return nil
  end
  return configDir .. string.gsub(string.gsub(root, '^/', ''), '/', '-') .. '.lua'
end

function InitProjectConfig()
  local configFile = getConfigFile()
  if configFile and vim.fn.filereadable(configFile) == 1 then
    vim.cmd('luafile ' .. configFile)
  end
end

function OpenProjectConfig()
  local configFile = getConfigFile()
  vim.cmd('vs ' .. configFile)
end

vim.cmd[[au VimEnter * ++once call v:lua.InitProjectConfig()]]
require('util').map('n', '<m-c>', ':call v:lua.OpenProjectConfig()<cr>')
