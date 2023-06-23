local function rpc_nvim_exec_lua(nvim_server, cmd)
  local chan_id = vim.fn.sockconnect("pipe", nvim_server, { rpc = true })
  local fzf_args = {}
  local c = vim.fn.argc()
  for i = 1, c do
    table.insert(fzf_args, vim.fn.argv(i - 1))
  end
  vim.print(fzf_args)

  vim.rpcrequest(chan_id, "nvim_exec_lua", [[
    local luaargs = {...}
    local cmd = luaargs[1]
    if cmd == 'preview' then
      FzfPreviewCb(luaargs[2])
    end
  ]], {
    cmd,
    fzf_args
  })
  vim.cmd [[qall]]
end

return {
  rpc_nvim_exec_lua = rpc_nvim_exec_lua
}
