local gitsign_data = {}
local gitsign_config = {
  a = { hl = 'diffAdded', icon = '│' },
  db = { hl = 'diffRemoved', icon = '‾'},
  dn = { hl = 'diffRemoved', icon = '_' },
  c = { hl = 'diffChanged', icon = '│' },
}

local function isInsideGitWorkTree()
  return vim.trim(vim.fn.system('git rev-parse --is-inside-work-tree')) == 'true'
end

local m = {}

m.sign = function()
  local lnum = vim.v.lnum
  local buf = vim.api.nvim_get_current_buf()
  if (gitsign_data[buf]) then
    local config = gitsign_config[gitsign_data[buf][lnum]]
    return gitsign_data[buf][lnum] and string.format('%%#%s#%s', config.hl, config.icon) or ' '
  end
  return ' '
end

m.setup = function()
  vim.api.nvim_create_autocmd({'BufEnter', 'TextChanged', 'TextChangedI'}, {
    callback = function()
      if (isInsideGitWorkTree() == false or vim.o.filetype == 'netrw') then
        return
      end
      local originFile = vim.fn.system('git show --no-color HEAD:./' .. vim.fn.expand('%'))
      local diff = vim.diff(originFile,
        vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, true), '\n'),
        {linematch = true, result_type = 'indices', ignore_whitespace_change_at_eol= true}
      )
      local buf = vim.api.nvim_get_current_buf()
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
          gitsign_data[buf][chunk[3]] = status
        elseif (status == 'db') then
          gitsign_data[buf][1] = status
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
