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

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    if vim.iter({'json', 'jsonc'}):find(vim.o.filetype) then
      vim.opt_local.conceallevel = 0
    end
  end
})

vim.api.nvim_create_autocmd('TextYankPost', {
  pattern = '*',
  callback = function()
    if vim.v.event.operator ~= 'y' then
      return
    end
    local text = vim.fn.getreg('"')
    if vim.v.event.regtype == 'V' then
      text = text:gsub('\n$', '')
    end
    vim.fn.setreg('+', text)
    vim.fn.setreg('*', text)
  end
})

if vim.env.TMUX and vim.fn.executable('tmux') == 1 then
  g.clipboard = 'tmux'
else
  g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = 'win32yank.exe -i --crlf',
      ['*'] = 'win32yank.exe -i --crlf',
    },
    paste = {
      ['+'] = 'win32yank.exe -o --lf',
      ['*'] = 'win32yank.exe -o --lf',
    },
    cache_enabled = 1,
  }
end
