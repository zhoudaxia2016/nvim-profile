-- 参考 https://github.com/SmiteshP/nvim-gps
local ts_utils = require("nvim-treesitter.ts_utils")
local ts_parsers = require("nvim-treesitter.parsers")
local ts_queries = require("nvim-treesitter.query")
local icons = {
  ["class-name"] = '',
  ["function-name"] = '',
  ["method-name"] = '',
  ["object-name"] = '',
  ["call-expression-name"] = '北'
}

local function transform(text, name)
  if icons[name] then
    text = icons[name] .. ' ' .. text
  end
  return text
end

HandleWinbarClick = function (i) end

function CodeLocation()
  local filelang = ts_parsers.ft_to_lang(vim.bo.filetype)
  local code_location_query = ts_queries.get_query(filelang, "code-location")

  if not code_location_query then
    return ''
  end

  local current_node = ts_utils.get_node_at_cursor()

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
    return string.format([[%%%s@v:lua.HandleWinbarClick@%s%%X]], i, transform(table.concat({vim.treesitter.query.get_node_text(_.node, 0)}, ' '), _.name))
  end, captures), ' > ')
end

vim.api.nvim_set_hl(0, 'WinBar', {
  bg = '#4C566A'
})

require('util').map('n', '<leader>p', ':echo v:lua.CodeLocation()<cr>', { silent = false })
vim.api.nvim_create_autocmd('BufLeave', {
  callback = function()
    vim.opt_local.winbar = ''
  end
})
vim.api.nvim_create_autocmd('BufEnter', {
  callback = function()
    if vim.tbl_contains({'javascript', 'typescript', 'typescriptreact', 'javascriptreact'}, vim.o.filetype) then
      vim.opt_local.winbar = '%!v:lua.CodeLocation()'
    end
  end
})
