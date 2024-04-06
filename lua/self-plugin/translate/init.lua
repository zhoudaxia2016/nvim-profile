local ts = vim.g.translateservice

local translate = function(source)
  if (ts == 'tencent') then
    require('self-plugin.translate.baidu')(source)
  else
    require('self-plugin.translate.baidu')(source)
  end
end

vim.keymap.set('n', '<leader>t', function()
  translate(vim.fn.expand('<cword>'))
end, {desc = 'Translate word at cursor'})

return translate
