local ns = vim.api.nvim_create_namespace('easy-motion')
local colorList = {
  {
    color = '#C19A6B',
    key = 'd',
    name = 'Desert'
  },
  {
    color = '#7B3F00',
    key = 'c',
    name = 'Chocolate'
  },
  {
    color = '#808080',
    key = 'g',
    name = 'Grey'
  },
  {
    color = '#000000',
    key = 'b',
    name = 'Black'
  },
  {
    color = '#ffffff',
    key = 'w',
    name = 'White'
  },
  {
    color = '#ff0000',
    key = 'r',
    name = 'red'
  },
  {
    color = '#ffef00',
    key = 'y',
    name = 'Yellow'
  },
  {
    color = '#800080',
    key = 'p',
    name = 'Purple'
  },
  {
    color = '#FFDBAC',
    key = 's',
    name = 'Skin'
  },
  {
    color = '#FF7F00',
    key = 'o',
    name = 'Orange'
  },
  {
    color = '#008080',
    key = 't',
    name = 'Teal'
  },
  {
    color = '#800000',
    key = 'm',
    name = 'Maroon'
  },
  {
    color = '#BFFF00',
    key = 'l',
    name = 'Lime'
  },
  {
    color = '#000080',
    key = 'n',
    name = 'Navy'
  },
  {
    color = '#00FFFF',
    key = 'a',
    name = 'Aqua'
  },
}
for _, item in pairs(colorList) do
  item.hlg = 'EasyMotion' .. item.name
  vim.cmd(string.format('hi %s guifg=%s', item.hlg, item.color))
end
function EasyMotion()
  local line = vim.fn.getline('.')
  local words = {}
  local s, e = string.find(line, '%w+', 1)
  while s ~= nil do
    s, e = string.find(line, '%w+', e + 1)
    if s ~= nil then
      table.insert(words, { s = s, e = e })
    end
  end
  if table.getn(words) > 0 then
    table.remove(words)
  end
  local lineNum = vim.fn.line('.')
  for i, col in pairs(words) do
    if i > table.getn(colorList) then
      break
    end
    vim.api.nvim_buf_set_extmark(0, ns, lineNum - 1, col.s - 1, { end_col = col.e, hl_group = colorList[i].hlg })
  end
  vim.defer_fn(function()
    local key = vim.fn.getcharstr()
    for i, v in pairs(colorList) do
      if key == v.key then
        if i <= table.getn(words) then
          vim.fn.cursor(lineNum, words[i].s)
        end
        break
      end
    end
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end, 0)
end

vim.api.nvim_set_keymap('n', 'f', '<Cmd>call v:lua.EasyMotion()<cr>', { silent = true })
