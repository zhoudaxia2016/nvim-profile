# 我的neovim配置

> 因为neovim相比vim支持更多的特性，配置语言lua相比vimscript好用100倍，所以从vim迁移到了neovim

[旧vim配置](https://github.com/zhoudaxia2016/vim-profile)

neovim内置了比较有用的功能：
- lsp
- treesitter

## lsp支持的功能
> 相比treesitter比较重量级，基于整个项目，支持比较完整的语法分析，对标ide的编译器

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

## treesitter支持的功能
> 相比lsp比较轻量，基于文件，提供比较初级的编辑体验，比如缩进，高亮

* highlight
* textobject
* code location
* indent
* incremental\_selection

## TODO
- [ ] 将所有配置从vim迁移到neovim
- [ ] 完善readme
