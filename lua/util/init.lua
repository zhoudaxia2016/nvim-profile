module = {}
function module.starts(s, start)
   return string.sub(s, 1, string.len(start)) == start
end
function module.trim(s)
  return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

return module
