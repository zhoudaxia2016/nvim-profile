local uv = vim.loop
local function jobstart(script, cb, cwd)
  if cwd == nil then
    cwd = vim.fn.getcwd()
  end
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local output_buf = ''
  local function update_chunk(_, chunk)
    if chunk ~= nil then
      output_buf = output_buf..chunk
    end
  end
  update_chunk = vim.schedule_wrap(update_chunk)

  -- luacheck: no unused
  local handle
  handle = uv.spawn("sh", {
    stdio = {stdin, stdout, stderr};
    cwd = cwd;
  }, function(code, signal)
    stdin:close()
    stdout:close()
    stderr:close()
    handle:close()
    if code == 0 and signal == 0 then
      vim.schedule(function() cb(output_buf) end)
    else
      print(1)
    end
  end)

  stdout:read_start(update_chunk)
  stderr:read_start(update_chunk)
  stdin:write(script)
  stdin:write("\n")
  stdin:shutdown()
end
return jobstart
