local ns = vim.api.nvim_create_namespace("a")

local function highlight_node(node)
  if not node then
    return
  end
  local start_row, _, end_row, _ = node:range()
  local end_row = vim.fn.line('$') == end_row and end_row or end_row + 1
  vim.api.nvim_buf_set_extmark(0, ns, start_row, 0, {hl_group = 'Scope', end_row = end_row, end_col = 0, hl_eol = true})
end

local function memoize(fn, hash_fn)
  local cache = setmetatable({}, { __mode = 'kv' }) ---@type table<any,any>

  return function(...)
    local key = hash_fn(...)
    if cache[key] == nil then
      local v = fn(...) ---@type any
      cache[key] = v ~= nil and v or vim.NIL
    end

    local v = cache[key]
    return v ~= vim.NIL and v or nil
  end
end

local get_matches = memoize(function(tree, query)
  local matchs = {}
  for _, match in query:iter_matches(tree:root(), query) do
    for id, nodes in pairs(match) do
      if query.captures[id] == 'local.scope' then
        for _, node in pairs(nodes) do
          table.insert(matchs, node)
        end
      end
    end
  end
  return matchs
end, function(tree)
  return tree:root():id()
end)

vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.o.filetype) or vim.o.filetype
    local query = vim.treesitter.query.get(lang, 'locals')
    if query == nil then
      return
    end
    local buf = args.buf
    vim.api.nvim_create_autocmd('CursorMoved', {
      callback = function()
        local tree = vim.treesitter.get_parser():parse()[1]
        local node = vim.treesitter.get_node()
        local parent
        local matchs = get_matches(tree, query)
        while node ~= nil do
          if vim.tbl_contains(matchs, node) then
            local start_row, _, end_row, _ = node:range()
            if end_row - start_row > 2 then
              parent = node
              break
            end
          end
          node = node:parent()
        end
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        if tree:root() == parent then
          return
        end
        highlight_node(parent)
      end,
      buffer = buf,
    })
    vim.api.nvim_create_autocmd('WinLeave', {
      callback = function()
        vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      end,
      buffer = buf,
    })
  end
})

