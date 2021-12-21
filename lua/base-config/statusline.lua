local o = vim.o
function ShowFileFormatFlag()
  return '[' .. o.fileformat .. ']'
end
o.laststatus = 2
local left = '%#Debug#   %{v:lua.GetLspDiagnostic()} %#Number#%y%{v:lua.ShowFileFormatFlag()} %#SpecialChar#Ln%l,Col%c%='
local right = '%<%L %#String#%F %#DiffChange#%p%%'
o.statusline = left .. right

local diagnostic = vim.diagnostic
local diagnostics = {
  error = {
    level = diagnostic.severity.ERROR,
    icon = ''
  },
  warn = {
    level = diagnostic.severity.WARN,
    icon = ''
  },
  info = {
    level = diagnostic.severity.HINT,
    icon = ''
  }
}

function GetLspDiagnostic()
  local s = {}
  for _, v in pairs(diagnostics) do
    local count = #diagnostic.get(0, { severity = v.level })
    if count > 0 then
      table.insert(s, v.icon .. count)
    end
  end
  if #s then
    return table.concat(s, ' ')
  end
end
