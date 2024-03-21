local o = vim.o
local opt = vim.opt
local g = vim.g
o.inccommand = 'split'
o.nu = true
o.relativenumber = true
o.scrolloff = 3
o.swb = 'useopen'
o.wrap = true
o.softtabstop = 2
o.shiftwidth = 2
o.tabstop = 2
o.expandtab = true
o.backspace = 'indent,eol,start'
o.ffs = 'unix,dos'
o.hidden = true
opt.diffopt:append('followwrap')
opt.shortmess:remove('S')
o.ignorecase = true
o.cursorline = true
o.writebackup = false
o.fileencodings='utf-8,chinese,latin-1,gbk,gb18030,gk2312'
o.lazyredraw = true
o.list = true
o.listchars = 'tab:  ,trail:_'
o.termguicolors = true
o.mouse = 'n'
o.undofile = true
o.undodir='/tmp/nvim/'
o.swapfile = false
o.switchbuf = 'useopen,usetab,newtab'
o.jumpoptions = 'stack'
g.netrw_use_noswf= 0
g.netrw_browsex_viewer="cmd.exe /C start"
o.conceallevel = 1
o.fixendofline = false
opt.iskeyword:append('-')
o.winblend = 24
o.smartcase = true

if o.diff then
  o.readonly = false
end

vim.cmd[[
  au VimEnter * if &diff | execute 'windo set wrap' | endif
  au FileType netrw setl bufhidden=delete
]]

vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = "*.json",
  callback = function()
    vim.opt_local.conceallevel = 0
  end
})

o.clipboard = 'unnamedplus'
local paste = function()
  return vim.split(vim.fn.getreg('"'), '\n')
end
g.clipboard =  {
  name = 'WslClipboard',
  copy = {
    ['+'] = 'clip.exe',
    ['*'] = 'clip.exe',
  },
  -- 粘贴系统clipboard直接用快捷键即可，不然会很慢（PowerShell问题）
  paste = {
    ['+'] = paste,
    ['*'] = paste,
  },
  cache_enabled = 1,
}
vim.keymap.set({'n', 'v'}, 'c', '"-c')
vim.keymap.set({'n', 'v'}, 'd', '"-d')
