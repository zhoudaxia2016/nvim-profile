local rootDir
local o = vim.o
local config
function GotoFile()
  local paths = config.paths
  local fname = vim.v.fname
  local isRelative = fname:find('^%./')
  for key, targets in pairs(paths) do
    key = key:gsub('%*', '(.*)')
    local finish
    if fname:match(key) then
      for _, value in ipairs(targets) do
        value = value:gsub('%*', '%%1')
        fname = fname:gsub(key, value)
        if isRelative == nil then
          fname = fname:gsub('^%.', config.baseUrl)
        end
        if vim.fn.filereadable(fname) then
          finish = true
          break
        end
      end
    end
    if finish then
      break
    end
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
    config = {}
    config.baseUrl = tsconfig.compilerOptions.baseUrl:gsub('%.', rootDir)
    config.paths = tsconfig.compilerOptions.paths
  end
  o.sua = o.sua .. ',.js' .. ',.ts' .. ',.tsx' .. ',.jsx'
  o.isfname = o.isfname .. ',@-@'
  o.includeexpr = 'v:lua.GotoFile()'
end
