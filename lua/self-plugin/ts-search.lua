local run = require('self-plugin.fzf').run
local previewer = require('self-plugin.fzf.previewer')

local extensionMap = {
  typescript = {'ts', 'tsx'},
  javascript = {'js', 'ts', 'jsx', 'tsx'},
}

vim.api.nvim_create_user_command('TsSearch', function()
  if (vim.o.filetype ~= 'query') then
    vim.notify('Not a query file!!!')
    return
  end

  local ft = vim.split(vim.fn.expand('%'), '/')[1]
  local extensions = extensionMap[ft]
  if extensions == nil then
    vim.notify('Not support filetype: ' .. ft)
    return
  end

  local cwd = vim.fn.getcwd() .. '/'
  local files = vim.fn.glob(string.format('**/*.{%s}', vim.fn.join(extensions, ',')), false, true)
  local paths = {}
  for _, f in ipairs(files) do
    table.insert(paths, cwd .. f)
  end

  local queryStr = vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')

  local input = {}
  for _, p in ipairs(paths) do
    local content = vim.fn.join(vim.fn.readfile(p), '\n')
    local tree = vim.treesitter.get_string_parser(content, ft):parse()
    local query = vim.treesitter.query.parse(ft, queryStr)
    local fn = p
    for id, node, metadata in query:iter_captures(tree[1]:root(), 0, 0, -1) do
      local name = query.captures[id] -- name of the capture in the query
      local type = node:type() -- type of the captured node
      local text = vim.treesitter.get_node_text(node, content)
      local row1, col1, row2, col2 = node:range() -- range of the capture
      table.insert(input, {info = {row1 = row1, col1 = col1, row2 = row2, col2 = col2, fn = fn}, text = text})
    end
  end

  run({
    input = input,
    getPreviewTitle = function(args)
      return args.info.fn
    end,
    previewCb = function(args, ns)
      local info = args.info
      local row1 = info.row1
      local row2 = info.row2
      local col1 = info.col1
      local col2 = info.col2
      local fn = info.fn
      previewer.file({
        fn = fn,
        row = row1,
        col = col1,
        ns = ns,
        selection = {
          startRange = {line = row1, character = col1},
          endRange = {line = row2, character = col2},
        }
      })
    end,
  })
end, {})
