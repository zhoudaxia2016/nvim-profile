# Neovim 配置 AGENTS.md

## 重要的行为准则

### 验证策略
用 luacheck 静态检查
不要用 `nvim --headless` 验证（除非用户主动要求）

### Neovim 配置问题
**文档搜索顺序**
1. 本地 Neovim 文档：`~/.local/nvim/share/nvim/runtime/doc/` 或 `:help vim.lsp.xxx`
2. 本地配置文件：grep 了解实际状态
3. GitHub issue/PR 查具体问题
4. 最后才 general web

### 修改前必读
读完整所有相关文件，再做判断
不要只读被提及的文件
