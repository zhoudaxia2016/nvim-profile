local function sudo_exec(cmd)
  vim.fn.inputsave()
  local password = vim.fn.inputsecret("Password: ")
  vim.fn.inputrestore()
  local out = vim.fn.system(string.format("sudo -p '' -S %s", cmd), password)
  if vim.v.shell_error ~= 0 then
    vim.notify(out)
    return false
  end
  return true
end

vim.api.nvim_create_user_command('SudoWrite', function()
  local tmpfile = vim.fn.tempname()
  local filepath = vim.fn.expand("%")
  local cmd = string.format("dd if=%s of=%s bs=1048576",
    vim.fn.shellescape(tmpfile),
    vim.fn.shellescape(filepath))
  vim.api.nvim_exec(string.format("write! %s", tmpfile), true)
  if sudo_exec(cmd) then
    vim.cmd("e!")
  end
  vim.fn.delete(tmpfile)
end, {})
