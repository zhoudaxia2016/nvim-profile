local o = vim.o
local Job = require'plenary.job'
local gitsign = ''
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
        print(1)
        match = string.gmatch(result[1], '%d+')
        match()
        local s = ''
        local addCount = match()
        if addCount then
          s = s .. '[+]' .. addCount
        end
        local deleteCount = match()
        if deleteCount then
          s = s .. '[-]' .. deleteCount
        end
        gitsign = s
      end
    end,
  }):start()
end
vim.cmd[[au BufEnter,BufWritePost * call v:lua.StatuslineGitSign()]]

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
for _, v in pairs(hlgs) do
  vim.cmd(string.format([[hi %s guifg=%s guibg=%s]], v.name, v.fg, v.bg))
end

function ShowFileFormatFlag()
  return '[' .. o.fileformat .. ']'
end
local leftList = {
  {
    hlg = hlgs.a,
    items = ' %f'
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
    items = '%y%{%v:lua.ShowFileFormatFlag()%} '
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
o.laststatus = 2
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

function GetLspDiagnostic()
  local s = {}
  for _, v in pairs(diagnostics) do
    local count = #diagnostic.get(0, { severity = v.level })
    if count > 0 then
      table.insert(s, string.format('%%#%s#%s %s%%#%s#', v.hlg, v.icon, count, v.hlg))
    end
  end
  if #s then
    return table.concat(s, ' ')
  end
end
