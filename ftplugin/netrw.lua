vim.cmd[[vertical res 20]]
local function map(k, t)
  vim.keymap.set('n', k, t, { buffer = true, remap = true })
end
map('h', '-')
map('l', '<cr>')
map('<c-l>', '<c-w><c-l>')
