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

vim.keymap.set('i', '<c-k>', function()
  local line = vim.fn.getline('.')
  local trigger = line:match('%w+$')
  local ft = vim.o.filetype
  if ft == 'typescript' or ft == 'typescriptreact' then
    ft = 'javascript'
  end

  local config = getConfig(ft)
  if config == nil or config[trigger] == nil then
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
