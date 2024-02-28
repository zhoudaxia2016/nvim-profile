-- snippet原则
-- trigger限制最长3，尽量2，可以1
-- trigger尽量截取body的begin，避免记忆
-- 只做常用的snippet

local cache = {}

local function readFile(name)
  local file = io.open(name)
  local json = file:read('*a')
  file:close()
  return json
end

local function getConfig(lang)
  local configFile = '/home/zhou/.config/nvim/lua/base-config/snippet/snippets/' .. lang .. '.json'
  if cache[lang] == nil and vim.fn.filereadable(configFile) == 1 then
    local json = readFile(configFile)
    json = vim.json.decode(json)
    local config = {}
    for _, v in pairs(json) do
      config[v.prefix] = v
    end
    cache[lang] = config
  end
  return cache[lang]
end

local extends = {
  typescript = {'javascript'},
  typescriptreact = {'javascript'},
  less = {'css'},
  sass = {'css'},
  scss = {'css'},
}

vim.keymap.set('i', '<c-k>', function()
  local line = vim.fn.getline('.')
  local trigger = line:match('%w+$')
  local ft = vim.o.filetype
  local fts = vim.fn.extend({ft}, extends[ft] or {})
  local config = {}
  for _, t in ipairs(fts) do
    local c = getConfig(t)
    config = vim.tbl_extend('keep', config, c or {})
  end

  if vim.tbl_isempty(config) or config[trigger] == nil then
    return
  end

  config = config[trigger]
  line = line:gsub('%w+$', '')
  vim.api.nvim_set_current_line(line)
  local body = type(config.body) == 'string' and config.body or vim.fn.join(config.body, '\n')
  vim.snippet.expand(body)
end)
vim.keymap.set('i', '<c-j>', function()
  vim.snippet.jump(1)
end)
