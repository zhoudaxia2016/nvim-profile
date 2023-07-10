local find_git_ancestor = require('lspconfig.util').find_git_ancestor
local o = vim.o
local Job = require'plenary.job'
local fzf = require('self-plugin.fzf.builtin')
local gitsign = ''
local fileIcons = {
  sass =  '',
  scss =  '',
  htm = '',
  html = '',
  css = '',
  less = '',
  md = '',
  markdown = '',
  json = '',
  javascript = '',
  mjs = '',
  javascriptreact = '',
  py = '',
  conf = '',
  ini = '',
  yml = '',
  yaml = '',
  cpp = '',
  c = '',
  h = '',
  lua = '',
  java = '',
  sh = '',
  go = '',
  vim = '',
  typescript = '',
  typescriptreact = '',
  vue = '﵂',
}

local hlgs = {
  a = {
    name = 'statusline_a',
    fg = '#3B4252',
    bg = '#88C0D0'
  },
  b = {
    name = 'statusline_b',
    fg = '#E5E9F0',
    bg = '#3B4252'
  },
  c = {
    name = 'statusline_c',
    fg = '#E5E9F0',
    bg = '#4C566A'
  }
}

hlgs.aTob = {
  name = 'statusline_a_to_b',
  fg = hlgs.a.bg,
  bg = hlgs.b.bg
}
hlgs.bToa = {
  name = 'statusline_b_to_a',
  fg = hlgs.b.bg,
  bg = hlgs.a.bg
}
hlgs.bToc = {
  name = 'statusline_b_to_c',
  fg = hlgs.b.bg,
  bg = hlgs.c.bg
}
hlgs.cTob = {
  name = 'statusline_c_to_b',
  fg = hlgs.c.bg,
  bg = hlgs.b.bg
}
hlgs.error = {
  name = 'statusline_error',
  fg = '#BF616A',
  bg = hlgs.c.bg
}
hlgs.warn = {
  name = 'statusline_warn',
  fg = '#EBCB8B',
  bg = hlgs.c.bg
}
hlgs.info = {
  name = 'statusline_info',
  fg = '#88C0D0',
  bg = hlgs.c.bg
}

local diagnostic = vim.diagnostic
local diagnostics = {
  error = {
    level = diagnostic.severity.ERROR,
    icon = '',
    hlg = hlgs.error.name
  },
  warn = {
    level = diagnostic.severity.WARN,
    icon = '',
    hlg = hlgs.warn.name
  },
  info = {
    level = diagnostic.severity.HINT,
    icon = '',
    hlg = hlgs.info.name
  }
}


function GetStatuslineGitsign()
  return gitsign .. ' '
end
function StatuslineGitSign()
  Job:new({
    command = 'git',
    args = { 'diff', '--shortstat', 'HEAD', vim.fn.expand('%') },
    on_exit = function(j, return_val)
      local result = j:result()
      if return_val == 0 and result[1] ~= nil then
        local s = {}
        local addCount = string.match(result[1], '(%d+)%s+%w+%(%+%)')
        if addCount then
          table.insert(s, '++ ' .. addCount)
        end
        local deleteCount = string.match(result[1], '(%d+)%s+%w+%(%-%)')
        if deleteCount then
          table.insert(s, ' ' .. deleteCount)
        end
        gitsign = table.concat(s, ' ')
      else
        gitsign = ''
      end
    end,
  }):start()
end
vim.cmd[[au BufEnter,BufWritePost * call v:lua.StatuslineGitSign()]]

for _, v in pairs(hlgs) do
  vim.cmd(string.format([[hi %s guifg=%s guibg=%s]], v.name, v.fg, v.bg))
end

function ShowFileType()
  local ft = vim.o.ft
  if fileIcons[ft] then
    ft = fileIcons[ft]
  end
  return '[' .. ft .. ']'
end

function ShowFileFormatFlag()
  local icons = {
    unix = '',
    mac = '',
    dos = '',
  }
  return ' ' .. icons[o.fileformat]
end
local menuName = 'statusline_list_files'
StatusbarHandlers = {
  file = function(_, _, button, modifier)
    -- TODO: bugfix 文件跳转后会yank
    if button == 'r' then
      local files = vim.split(vim.fn.expand('*'), '\n')
      for _, f in pairs(files) do
        f = vim.fn.escape(f, '.')
        vim.cmd(('noremenu %s.%s :tabnew %s<cr>'):format(menuName, f, f))
      end
      vim.cmd('popu! ' .. menuName)
      vim.cmd('unmenu ' .. menuName)
      return
    end
    local fn = '%:p'
    modifier = vim.fn.trim(modifier)
    if modifier == '' then
      local gitroot = find_git_ancestor(vim.fn.expand('%:p'))
      local lspClients = vim.lsp.get_active_clients()
      local root = lspClients and lspClients[1].config.root_dir or gitroot
      if root then
        fn = fn .. string.format(':s?%s/??', root)
      end
    elseif modifier == 'c' then
      fn = '%'
    end
    require('util').copy(vim.fn.expand(fn))
  end,
  diagnostic = function(n, _, button)
    if button == 'l' then
      local diagnosticConfig = { severity = n, float = { border = "rounded" }}
      vim.diagnostic.goto_next(diagnosticConfig)
    else
      -- TODO Why need to delay?
      vim.defer_fn(function()
        fzf.diagnostic(n)
      end, 200)
    end
  end
}
local leftList = {
  {
    hlg = hlgs.a,
    items = ' %@v:lua.StatusbarHandlers.file@%-0.100F%X'
  },
  {
    hlg = hlgs.aTob,
    items = ''
  },
  {
    hlg = hlgs.b,
    items = ' %l:%c '
  },
  {
    hlg = hlgs.bToc,
    items = ''
  },
  {
    hlg = hlgs.c,
    items = ' %{%v:lua.GetLspDiagnostic()%}'
  },
}
local rightList = {
  {
    hlg = hlgs.c,
    items = '%{%v:lua.GetStatuslineGitsign()%}'
  },
  {
    hlg = hlgs.c,
    items = '%{%v:lua.ShowFileType()%}%{%v:lua.ShowFileFormatFlag()%} '
  },
  {
    hlg = hlgs.bToc,
    items = ''
  },
  {
    hlg = hlgs.b,
    items = ' %L '
  },
  {
    hlg = hlgs.aTob,
    items = ''
  },
  {
    hlg = hlgs.a,
    items = '%p%% '
  }
}
local statusline = ''
local function concatStatusline(list)
  for _, v in pairs(list) do
    if v.hlg then
      statusline = statusline .. string.format('%%#%s#%s', v.hlg.name, v.items)
    else
      statusline = statusline .. string.format('%s', v.items)
    end
  end
end
concatStatusline(leftList)
statusline = statusline .. '%=%<'
concatStatusline(rightList)
o.statusline = statusline
o.laststatus = 3

function GetLspDiagnostic()
  local s = {}
  for _, v in pairs(diagnostics) do
    local count = #diagnostic.get(0, { severity = v.level })
    if count > 0 then
      table.insert(s, string.format('%%#%s#%%%s@v:lua.StatusbarHandlers.diagnostic@%s %s%%X%%#%s#', v.hlg, v.level, v.icon, count, v.hlg))
    end
  end
  if #s then
    return table.concat(s, ' ')
  end
end
