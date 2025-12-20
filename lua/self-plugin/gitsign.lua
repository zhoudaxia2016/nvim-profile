local gitsign_data = {}
local gitsign_config = {
  a = { hl = 'diffAdded', icon = '│' },
  db = { hl = 'diffRemoved', icon = '‾'},
  dn = { hl = 'diffRemoved', icon = '_' },
  c = { hl = 'diffChanged', icon = '│' },
  cd = { hl = 'diffChanged', icon = '~' },
}

local function executeShell(cmd, useBuf)
  local dir = vim.fs.dirname(vim.fn.expand('%:p'))
  local fn = useBuf and vim.fn.expand('%:t') or ''
  return vim.fn.system(string.format('cd %s;%s%s', dir, cmd, fn))
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

local isInsideGitWorkTree = memoize(function(buf)
  local res = executeShell('git rev-parse --is-inside-work-tree') == 'true'
  if (res == true) then
    return executeShell('git check-ignore ', true) == ''
  end
  return res
end, function(buf)
  return tostring(buf)
end)

local function getDiff()
  local originFile = executeShell('git show --no-color :./', true)
  return vim.diff(originFile,
    vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, true), '\n'),
    {linematch = true, result_type = 'indices', ignore_whitespace_change_at_eol= true}
  )
end

local m = {}

m.sign = function()
  local lnum = vim.v.lnum
  local buf = vim.api.nvim_get_current_buf()
  if (isInsideGitWorkTree(buf) == false) then
    return ''
  end
  if (gitsign_data[buf]) then
    local config = gitsign_config[gitsign_data[buf][lnum]]
    return gitsign_data[buf][lnum] and string.format('%%#%s#%s', config.hl, config.icon) or ' '
  end
  return ' '
end

m.setup = function()
  vim.api.nvim_create_autocmd({'BufEnter', 'TextChanged', 'TextChangedI'}, {
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if (isInsideGitWorkTree(buf) == false or vim.o.filetype == 'netrw') then
        return
      end
      local diff = getDiff()
      gitsign_data[buf] = {}
      for _, chunk in ipairs(diff) do
        local status = 'c'
        if (chunk[2] == 0) then
          status = 'a'
        elseif (chunk[3] == 0) then
          status = 'db'
        elseif (chunk[4] == 0) then
          status = 'dn'
        end
        if (status == 'dn') then
          local oldStatus = gitsign_data[buf][chunk[3]]
          gitsign_data[buf][chunk[3]] = oldStatus == 'c' and 'cd' or status
        elseif (status == 'db') then
          local oldStatus = gitsign_data[buf][chunk[1]]
          gitsign_data[buf][chunk[1]] = oldStatus == 'c' and 'cd' or status
        else
          for i = chunk[3], chunk[3] + chunk[4] - 1 do
            gitsign_data[buf][i] = status
          end
        end
      end
    end
  })
end

return m
