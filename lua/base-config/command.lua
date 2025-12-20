local autoSaveAutoCmdId
vim.api.nvim_create_user_command('ToggleAutoSave', function()
  if autoSaveAutoCmdId then
    vim.api.nvim_del_autocmd(autoSaveAutoCmdId)
    autoSaveAutoCmdId = nil
    vim.notify('AutoSave Mode is closed!')
  else
    autoSaveAutoCmdId = vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
      pattern = { "*" },
      command = "silent! w",
      nested = true,
    })
    vim.notify('AutoSave Mode is opened!')
  end
end, {})
