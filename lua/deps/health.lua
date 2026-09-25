local M = {}

local deps = {
  git = 'gitsign、features.git（diff、跳文件）',
  ['tree-sitter'] = 'nvim-treesitter 安装/编译 parser 需要它；而安装期间编辑器不响应输入（vim.wait）',
  curl = 'nvim-treesitter 下载 parser 源码',
  tar = 'nvim-treesitter 解包 parser 源码',
  node = 'ts_ls、features.jest-runner',
  fzf = 'plugins.fzf 文件跳转',
  tmux = 'features.agent（可选：只在 tmux 会话里用）',
}
local optional = { tmux = true }

local function check_bins()
  vim.health.start('外部依赖命令')
  local bins = {}
  for bin in pairs(deps) do
    bins[#bins + 1] = bin
  end
  table.sort(bins)
  for _, bin in ipairs(bins) do
    if vim.fn.executable(bin) == 1 then
      vim.health.ok(('%s → %s'):format(bin, vim.fn.exepath(bin)))
    elseif optional[bin] then
      vim.health.info(('%s 未安装（可选）：%s'):format(bin, deps[bin]))
    else
      vim.health.error(('%s 未安装'):format(bin), { '用于：' .. deps[bin] })
    end
  end
end

local function check_lsp()
  vim.health.start('LSP 服务端')
  -- _enabled_configs 是 vim.lsp.enable() 启用的那批，比手写 server 列表可靠
  local enabled = vim.lsp._enabled_configs
  if not enabled then
    vim.health.warn('拿不到 vim.lsp._enabled_configs，跳过（nvim 版本变了？）')
    return
  end

  local servers = {}
  for name in pairs(enabled) do
    servers[#servers + 1] = name
  end
  table.sort(servers)
  for _, name in ipairs(servers) do
    local cmd = (vim.lsp.config[name] or {}).cmd
    if cmd == nil then
      vim.health.warn(('%s：取不到 cmd，确认 lspconfig 里有这个 server 名'):format(name))
    elseif type(cmd) == 'function' then
      vim.health.info(('%s：cmd 由函数动态生成，跳过'):format(name))
    elseif vim.fn.executable(cmd[1]) == 1 then
      vim.health.ok(('%s → %s'):format(name, table.concat(cmd, ' ')))
    else
      vim.health.error(('%s 的命令行找不到：%s'):format(name, cmd[1]), {
        '完整启动命令：' .. table.concat(cmd, ' '),
      })
    end
  end
end

-- 期望装好的 parser（对应 lua/plugins/treesitter.lua 里的 langs，那边加了语言这里跟着加）
-- 完整清单/查询文件状态看 :checkhealth nvim-treesitter
local want_parsers = {
  'javascript', 'typescript', 'tsx', 'lua', 'json', 'jsonc', 'query', 'comment',
  'scheme', 'markdown', 'markdown_inline', 'toml', 'rust', 'go', 'c', 'cpp',
  'cmake', 'git_config', 'kotlin', 'java', 'lean',
}

local function check_parsers()
  vim.health.start('Treesitter parser')
  local installed = require('nvim-treesitter').get_installed()
  local missing = {}
  for _, lang in ipairs(want_parsers) do
    if not vim.list_contains(installed, lang) then
      missing[#missing + 1] = lang
    end
  end

  if #missing == 0 then
    vim.health.ok(('%d 个 parser 都在'):format(#want_parsers))
  else
    vim.health.warn(
      ('%s 未安装（%d/%d）'):format(table.concat(missing, ' '), #missing, #want_parsers),
      {
        '首次打开这类文件会触发 nvim-treesitter 下载+编译，期间编辑器不响应输入',
        "预装：:lua require('nvim-treesitter').install({ ... })",
      }
    )
  end
end

function M.check()
  check_bins()
  check_lsp()
  check_parsers()
end

return M
