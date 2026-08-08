-- Load all module from a directory
return function(dir)
  local scan = require'plenary.scandir'
  local files = scan.scan_dir(vim.fn.stdpath('config') .. '/lua/' .. dir, { depth = 1, add_dirs = 1 })
  for i = 1, #files do
    local f
    -- Normalize path separators for cross-platform compatibility (Windows uses \)
    local normalized = files[i]:gsub('\\', '/')
    if vim.fn.isdirectory(files[i]) == 1 then
      f = normalized:match("^.+/(.+)$")
    else
      f = normalized:match("^.+/(.+)%..+$")
    end
    if f ~= 'init' then
      require(dir .. '.' .. f)
    end
  end
end
