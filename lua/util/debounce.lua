local function debounce (fn, delay)
  local timer
  return function(...)
    local args={...}
    if timer and timer:is_closing() == false then
      timer:stop()
      timer:close()
    end
    timer = vim.defer_fn(function()
      fn(unpack(args))
    end, delay)
  end
end
return debounce
