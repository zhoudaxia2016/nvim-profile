local basePath = vim.env.HOME .. '/.config/nvim/dict/'
local queries = vim.treesitter.query

local function dictCollect()
  local ft = vim.o.ft
  local queryFiles = vim.treesitter.get_query_files(ft, 'highlights')
  local dict = {
    keyword = {},
    builtin = {}
  }
  for _, f in ipairs(queryFiles) do
    local file = io.open(f)
    local queryContent = file:read('*a')
    file:close()
    local parser = vim.treesitter.get_string_parser(queryContent, 'query')
    local tstree = parser:parse()
    local query = queries.get_query('query', 'keyword-builtin')
    local captures = query.captures

    for id, node, metadata in query:iter_captures(tstree[1]:root(), queryContent) do
      local text = queries.get_node_text(node, queryContent)
      text = string.gsub(text, '^"(.*)"$', '%1')
      if (dict[captures[id]] ~= nil and #text > 3) then
        table.insert(dict[captures[id]], text)
      end
    end
  end

  local file = io.open(basePath .. ft .. '.dict', 'w')
  io.output(file)
  io.write(table.concat(dict.keyword, '\n'))
  io.close(file)
end

vim.api.nvim_create_user_command('DictCollect', dictCollect, {})
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    local ft = vim.o.ft
    vim.bo.dictionary = basePath .. ft .. '.dict'
  end
})
