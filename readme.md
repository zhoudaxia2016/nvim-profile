# 我的neovim配置

因为neovim相比vim支持更多的特性，配置语言lua相比vimscript更好维护，所以从vim迁移到了neovim
使用dev版本neovim，尝鲜最新features，方便debug问题

[旧vim配置](https://github.com/zhoudaxia2016/vim-profile)

neovim内置了代码编辑器重要特性：
- [lsp](https://langserver.org/)
- [treesitter](https://tree-sitter.github.io/tree-sitter/)


## :stars: lsp支持的功能
相比treesitter比较重量级，基于整个项目，支持比较完整的语法分析，lsp是vscode抽离出来的协议，理论上可以实现vscode大部分语法分析的功能

- definition
- completion
- references
- documentHighlight
- hover
- references
- diagnostics
- typeDefinition
- refactor
- rename
- inlayhints(比较鸡肋)

## :stars: treesitter支持的功能
相比lsp比较轻量，基于文件，提供比较初级的编辑体验，比如缩进，高亮

* highlight
* textobject
* code location
* indent
* incremental\_selection

## :vertical_traffic_light: 原则
1. 尽量不引入插件
2. 适当搭配其他工具（fzf，tmux）

## 🚀 插件管理
用vim自带的插件管理器，插件直接放在pack目录下即可
另外，这些插件用git submodule进行管理

## :hourglass: TODO
- [ ] 将所有配置从vim迁移到neovim
- [ ] 完善readme
