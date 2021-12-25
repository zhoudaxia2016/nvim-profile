function Replace()
  vim.ui.input({
    prompt = '请输入查找的单词'
  }, function(search)
    if search then
      vim.ui.input({
        prompt = '请输入替换的单词'
      }, function(sub)
        vim.cmd(string.format('1,$s/%s/%s/gc', search, sub))
      end)
    end
  end)
end
require('util').map('n', '<leader>r', ':call v:lua.Replace()<cr>')
