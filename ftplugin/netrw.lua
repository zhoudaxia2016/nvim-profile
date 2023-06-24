if vim.api.nvim_win_get_config(0).relative == '' then
  vim.cmd[[vertical res 20]]
end
local function map(k, t)
  vim.keymap.set('n', k, t, { buffer = true, remap = true })
end
map('h', '-')
map('l', '<cr>')
map('<c-l>', '<c-w><c-l>')
