local get_node_text = vim.treesitter.get_node_text

local function getTestName(node)
  if node == nil then return nil end
  if node:type() == 'call_expression' then
    local text = get_node_text(node:named_child(1), 0)
    local name = ''
    if text == 'describe' or text == 'it' then
      name = get_node_text(node:named_child(2):named_child(1):named_child(1))
      if text == 'it' then
        name = getTestName(node:parent()) .. " " .. name
      end
      return name
    else
      return getTestName(node:parent())
    end
  end
  return getTestName(node:parent())
end

local loadedConfig = false
local workspace
local configFile
local bin

local function runJestTest(debug)
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
  local name = getTestName(node) or ''
  local fn = vim.fn.expand('%:p')
  local debugArgs = ''
  if debug == 1 then
    debugArgs = '--inspect-brk'
  end
  vim.cmd[[tabnew]]
  vim.fn.termopen(string.format('node %s %s %s -c %s -t "%s"', debugArgs, bin, fn, configFile, name), { cwd = workspace })
end

require('util').map('n', '<m-t><m-t>', function()
  runJestTest()
end, {desc = 'Run jest test'})
require('util').map('n', '<m-t><m-u>', function()
  runJestTest(1)
end, {desc = 'Debug jest test'})
