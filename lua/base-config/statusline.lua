local o = vim.o

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
o.laststatus = 2
local left = string.format('%%#%s# %%f%%#%s#%%#%s# %%l:%%c %%#%s#%%#%s# %%{%%v:lua.GetLspDiagnostic()%%}%%=', hlgs.a.name, hlgs.aTob.name, hlgs.b.name, hlgs.bToc.name, hlgs.c.name)
local right = string.format('%%#%s#%%<%%y%%{v:lua.ShowFileFormatFlag()} %%#%s#%%#%s# %%L %%#%s#%%#%s#%%p%%%% ', hlgs.c.name, hlgs.bToc.name, hlgs.b.name, hlgs.aTob.name, hlgs.a.name)
o.statusline = left .. right

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
