local ts_utils = require('nvim-treesitter.ts_utils')

local function getTestName(node)
  if node == nil then return nil end
  if node:type() == 'call_expression' then
    local children = ts_utils.get_named_children(node)
    local text = ts_utils.get_node_text(children[1])[1]
    if text == 'describe' or text == 'it' then
      return ts_utils.get_node_text(ts_utils.get_named_children(children[2])[1])[1]
    end
  end
  return getTestName(node:parent())
end

local loadedConfig = false
local workspace
local configFile
local bin

function RunJestTest(debug)
  if loadedConfig == false then
    if vim.g.jestRunner == nil then return end
    workspace = vim.g.jestRunner.workspace
    configFile = vim.g.jestRunner.configFile
    bin = vim.g.jestRunner.bin
    vim.validate({
      workspace = {workspace, 'string'},
      configFile = {configFile, 'string'},
      bin = {bin, 'string'}
    })
  end
  loadedConfig = true

  local node = ts_utils.get_node_at_cursor()
  local name = getTestName(node)
  local fn = vim.fn.expand('%:p')
  local debugArgs = ''
  if debug == 1 then
    debugArgs = '--inspect-brk'
  end
  vim.cmd[[tabnew]]
  vim.fn.termopen(string.format('node %s %s %s -c %s -t %s', debugArgs, bin, fn, configFile, name), { cwd = workspace })
end

require('util').map('n', '<m-t><m-t>', ':call v:lua.RunJestTest()<cr>')
require('util').map('n', '<m-t><m-u>', ':call v:lua.RunJestTest(1)<cr>')
