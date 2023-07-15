local M = {}
local fns = {}
M.registerFn = function(id, fn, label)
  fns[id] = fn
  return ("%%%d@v:lua.require'base-config.statusline.utils'.callFn@%s%%X"):format(id, label)
end

M.callFn = function(id, n, btn, m)
  fns[id](n, btn, m)
end

return M
