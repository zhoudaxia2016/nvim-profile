vim.api.nvim_set_keymap('n', '<M-l><M-w>', '<Plug>(Luadev-RunWord)', {})
vim.api.nvim_set_keymap('n', '<M-l><M-l>', '<Plug>(Luadev-RunLine)', {})
vim.api.nvim_set_keymap('n', '<M-l><M-n>', '<Plug>(Luadev-Run)', {})
vim.api.nvim_set_keymap('n', '<M-l><M-q>', 'v:lua.LuaDevTestFunc', {})

-- 测试lua脚本方式
-- 新建一个lua文件，执行luadev，然后执行luadev的执行命令映射
-- 映射有 执行当前单词 执行当前行 执行textobject或者move
-- 如果某些命令依赖光标位置，则新建function LuaDevTestFunc，通过映射<m-l><m-q>执行
--
-- 这样做优点:
-- 历史记录获取更方便
-- 执行结果获取更方便
-- 可以执行多行命令
-- lua智能提示
