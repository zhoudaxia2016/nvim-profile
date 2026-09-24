-- filetype 为 qf 的缓冲区有两种：quickfix 窗口和 location list 窗口（document_symbol、
-- diagnostic.setloclist 打开的都是后者）。':.cc' 只作用于 quickfix 列表，在 location list
-- 窗口里那个列表通常是空的，于是报 E42: No Errors，要改用 ':.ll'。
-- 窗口类型按下 <cr> 时判断最准，所以放进 <Cmd> 里分发；rhs 保持字符串，
-- keymap.lua 的 patchEnter 才能继续把它复制给 <tab>。
vim.keymap.set(
  'n',
  '<cr>',
  [[<Cmd>lua vim.cmd(vim.fn.getqflist({ winid = 0 }).winid == vim.api.nvim_get_current_win() and '.cc' or '.ll')<CR>]],
  { buffer = true }
)
