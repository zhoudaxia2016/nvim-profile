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

function GetCodeLocation()
  local filelang = ts_parsers.ft_to_lang(vim.bo.filetype)
  local code_location_query = ts_queries.get_query(filelang, "code-location")

  if not code_location_query then
    return "error"
  end

  local current_node = ts_utils.get_node_at_cursor()

  local node_text = {}
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
        table.insert(node_text, 1, transform(table.concat(ts_utils.get_node_text(capture_node), ' '), capture_name))

      end
    end

    node = node:parent()
  end

  local context = table.concat(node_text, ' > ')
  print(context)
end

require('util').map('n', '<leader>p', ':call v:lua.GetCodeLocation()<cr>', { silent = false })
