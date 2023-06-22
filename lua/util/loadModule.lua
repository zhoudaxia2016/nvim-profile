-- Load all module from a directory
return function(dir)
  local scan = require'plenary.scandir'
  local files = scan.scan_dir(vim.env.HOME .. '/.config/nvim/lua/' .. dir, { depth = 1, add_dirs = 1 })
  for i = 1, #files do
    local f
    if vim.fn.isdirectory(files[i]) == 1 then
      f = files[i]:match("^.+/(.+)$")
    else
      f = files[i]:match("^.+/(.+)%..+$")
    end
    if f ~= 'init' then
      require(dir .. '.' .. f)
    end
  end
end
