local ts_utils = require('nvim-treesitter.ts_utils')
local util = require('lspconfig.util')
local config
local exts = {'ts', 'js', 'tsx', 'jsx'}
local pattern = vim.tbl_map(function(ext)
  return '*.' .. ext
end, exts)

local function readFile(name)
  local file = io.open(name)
  local json = file:read('*a')
  file:close()
  return json
end

local function readJsonFile(name)
  local json = readFile(name)
  json = json:gsub('%s*//[^\n]*\n', '')
  json = json:gsub(',(%s*\n%s*[%]}])', '%1')
  return vim.fn.json_decode(json)
end

local function checkPathAndGo(f)
  local paths = {}

  if (vim.fn.filereadable(f) == 1) then
    vim.cmd('e ' .. f)
    return true
  end
  if vim.fn.isdirectory(f) == 1 then
    local slash = '/'
    if f:match('/$') then
      slash = ''
    end
    for _, ext in pairs(exts) do
      table.insert(paths, f .. slash .. 'index.' .. ext)
    end
  else
    for _, ext in pairs(exts) do
      table.insert(paths, f .. '.' .. ext)
    end
  end
  for _, p in pairs(paths) do
    if vim.fn.filereadable(p) == 1 then
      vim.cmd('e ' .. p)
      return true
    end
  end
  return nil
end

local function init()
  if config then
    return
  end
  local rootDir = util.find_package_json_ancestor(vim.fn.getcwd())
  if rootDir == nil then return end
  local tsconfigFile = rootDir .. '/tsconfig.json'
  config = {
    paths = {}
  }
  if vim.fn.filereadable(tsconfigFile) == 1 then
    local tsconfig = readJsonFile(rootDir .. '/tsconfig.json')
    if tsconfig.compilerOptions and tsconfig.compilerOptions.paths then
      config = { baseUrl = './' }
      if tsconfig.compilerOptions.baseUrl ~= nil then
        config.baseUrl = tsconfig.compilerOptions.baseUrl:gsub('%.', rootDir)
      end
      config.paths = tsconfig.compilerOptions.paths
    end
  end
end

local function gotoFile()
  init()
  local paths = config.paths
  local node = ts_utils.get_node_at_cursor(0)
  if node:type() ~= 'string_fragment' then
    return 'gf'
  end
  local fname = vim.treesitter.query.get_node_text(node, 0)
  local isRelative = fname:find('^%./')
  for key, targets in pairs(paths) do
    key = key:gsub('%*', '(.*)')
    key = key:gsub('%-', '%%-')
    if fname:match(key) then
      for _, value in ipairs(targets) do
        if value == '' then
          key = key:gsub('%.%*', '')
        end
        value = value:gsub('%*', '%%1')
        fname = fname:gsub(key, value)
        if checkPathAndGo(fname) then
          return
        end
        if isRelative == nil then
          fname = fname:gsub('^%.?', config.baseUrl)
        end
        if checkPathAndGo(fname) then
          return
        end
      end
    end
  end
  if checkPathAndGo(fname) then
    return
  end
  vim.notify('Can not go to file: ' .. fname)
end

vim.api.nvim_create_autocmd('BufEnter', {
  pattern = pattern,
  callback = function()
    vim.keymap.set('n', 'gf', gotoFile)
  end
})

vim.api.nvim_create_autocmd('VimEnter', {
  pattern = pattern,
  callback = function()
    init()
  end
})

