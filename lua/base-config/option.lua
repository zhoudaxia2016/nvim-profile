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
o.foldmethod = 'indent'
o.foldlevel = 3
o.ffs = 'unix,dos'
o.hidden = true
opt.foldopen:append('jump')
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
g.netrw_use_noswf= 0
g.netrw_browsex_viewer="cmd.exe /C start"
g.vim_json_conceal=0

if o.diff then
  o.readonly = false
end

vim.cmd[[
  au VimEnter * if &diff | execute 'windo set wrap' | endif
  au FileType netrw setl bufhidden=delete
]]
