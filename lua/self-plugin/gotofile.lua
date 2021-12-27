local rootDir
local o = vim.o
local config
local exts = {'ts', 'js', 'tsx'}

local function getPath(f)
  local paths = {}

  if vim.fn.isdirectory(f) == 1 then
    for _, ext in pairs(exts) do
      table.insert(paths, f .. 'index.' .. ext)
    end
  else
    for _, ext in pairs(exts) do
      table.insert(paths, f .. '.' .. ext)
    end
  end
  for _, p in pairs(paths) do
    if vim.fn.filereadable(p) == 1 then
      return p
    end
  end
  return nil
end
function GotoFile()
  local paths = config.paths
  local fname = vim.v.fname
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
        local p = getPath(fname)
        if p then
          return p
        end
        if isRelative == nil then
          fname = fname:gsub('^%.', config.baseUrl)
        end
        p = getPath(fname)
        if p then
          return p
        end
      end
    end
  end
  local p = getPath(fname)
  if p then
    return p
  end
  return fname
end

vim.cmd[[au BufRead *.tsx,*.jsx,*.js,*.ts call v:lua.ConfigGotoFile()]]

local function readFile(name)
  local file = io.open(name)
  local json = file:read('*a')
  file:close()
  return json
end

local function readJsonFile(name)
  local json = readFile(name)
  json = json:gsub('%s*//[^\n]*\n', '')
  return vim.fn.json_decode(json)
end

function ConfigGotoFile()
  if config == nil then
    local configFile = 'package.json'
    rootDir = vim.fn['utils#findRoot'](configFile)
    if rootDir == vim.NIL then return end
    local tsconfig = readJsonFile(rootDir .. '/tsconfig.json')
    if tsconfig.compilerOptions and tsconfig.compilerOptions.paths then
      config = { baseUrl = './' }
      if tsconfig.compilerOptions.baseUrl ~= nil then
        config.baseUrl = tsconfig.compilerOptions.baseUrl:gsub('%.', rootDir)
      end
      config.paths = tsconfig.compilerOptions.paths
    end
  end
  o.sua = o.sua .. ',.js' .. ',.ts' .. ',.tsx' .. ',.jsx'
  o.isfname = o.isfname .. ',@-@,!'
  o.includeexpr = 'v:lua.GotoFile()'
end
