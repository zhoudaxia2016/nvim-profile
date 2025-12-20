-- 参考 https://github.com/SmiteshP/nvim-gps
local utils = require('util')

local function createColorGroup(link)
  return utils.createColorGroup({bg = '#4c566a'}, 'winbar_', link)
end

local config = {
  ["class-name"] = { icon = '󰌗', hl = createColorGroup('@constructor') },
  ["function-name"] = { icon = '󰊕', hl = createColorGroup('@function') },
  ["method-name"] = { icon = '󰆧', hl = createColorGroup('@method') },
  ["object-name"] = { icon = '󰅩', hl = createColorGroup('@variable') },
  ["call-expression-name"] = { icon = '♺', hl = createColorGroup('@function.call') }
}

local delimiterColorGroup = createColorGroup('Comment')
local defaultColorGroup = createColorGroup('@variable')

local function transform(text, name)
  if config[name] then
    local icon = config[name].icon and config[name].icon .. ' ' or ''
    local hl = config[name].hl or ''
    text = string.format('%%#%s#%s%s', hl, icon, text)
  end
  text = text:gsub('\n%s*', '')
  return string.format('%%#@%s#%s', defaultColorGroup, text)
end

HandleWinbarClick = function () end

function CodeLocation()
  local filelang = vim.treesitter.language.get_lang(vim.bo.filetype) or vim.bo.filetype
  local code_location_query = vim.treesitter.query.get(filelang, "code-location")

  if not code_location_query then
    return ''
  end

  local current_node = vim.treesitter.get_node({})

  local captures = {}
  local node = current_node

  while node do
    local iter = code_location_query:iter_captures(node, 0)
    local capture_ID, capture_node = iter()

    if capture_node == node then
      if code_location_query.captures[capture_ID] == "scope-root" then

        while capture_node == node do
          capture_ID, capture_node = iter()
        end
        local capture_name = code_location_query.captures[capture_ID]
        table.insert(captures, 1, { node = capture_node, name = capture_name })
      end
    end

    node = node:parent()
  end

  HandleWinbarClick = function(i)
    local r, c = captures[i].node:start()
    vim.cmd(string.format([[normal %sG%s|]], r + 1, c + 1))
  end

  local i = 0
  return table.concat(vim.tbl_map(function(_)
    i = i + 1
    return string.format([[%%%s@v:lua.HandleWinbarClick@%s%%X]], i, transform(table.concat({vim.treesitter.get_node_text(_.node, 0)}, ' '), _.name))
  end, captures), string.format('%%#%s# > ', delimiterColorGroup))
end

vim.api.nvim_set_hl(0, 'WinBar', {
  bg = '#4C566A'
})

vim.keymap.set('n', '<leader>p', ':echo v:lua.CodeLocation()<cr>', {})
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    if vim.tbl_contains({'javascript', 'typescript', 'typescriptreact', 'javascriptreact', 'lua', 'c', 'cpp', 'jsonc', 'json'}, vim.o.filetype) then
      vim.opt_local.winbar = '%!v:lua.CodeLocation()'
    end
  end
})
