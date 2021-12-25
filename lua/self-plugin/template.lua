local fn = vim.fn
local cmd = vim.cmd
cmd'au BufNewFile * call v:lua.LoadTemplate()'

function LoadTemplate()
  local ft = vim.o.filetype
  local args = {filename = vim.fn.expand("%")}
  local tpf = vim.env.HOME .. '/.config/nvim/templates/files/' .. ft .. '.tpl'

  if fn.filereadable(tpf) == 1 then
    cmd('r ' .. tpf)
    cmd('1,1delete')
  else
    return
  end

  for key, value in pairs(args) do
    cmd(':1,$s/{%' .. key .. '%}/' .. value .. '/ge')
  end
  local pattern = '{%[^%]*%}'

  cmd'redraw'
  while 1 do
    local status = xpcall(cmd, debug.traceback, '/' .. pattern)
    if status then
      cmd("normal! n")
      local key = fn.expand('<cword>')
      vim.ui.input({
        prompt = "Input " .. key .. ": "
      }, function(value)
        cmd(string.format(':1,$s/{%%%s%%}/%s/ge', key, value))
      end)
    else
      fn.feedkeys('<cr>')
      break
    end
  end
end
