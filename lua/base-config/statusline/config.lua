local fzf = require('self-plugin.fzf.builtin')
local hlgs = require('base-config.statusline.hlgs')
local gitsign = require('base-config.statusline.gitsign')
local fileIcons = require('base-config.statusline.fileIcons')
local find_git_ancestor = require('lspconfig.util').find_git_ancestor
local icons = require"util.icons"
local diagnostic = vim.diagnostic
local o = vim.o
local diagnostics = {
  error = {
    level = diagnostic.severity.ERROR,
    icon = icons.cross,
    hlg = hlgs.error.name
  },
  warn = {
    level = diagnostic.severity.WARN,
    icon = icons.exclamation_reverse,
    hlg = hlgs.warn.name
  },
  info = {
    level = diagnostic.severity.HINT,
    icon = icons.bulb,
    hlg = hlgs.info.name
  }
}

local function makeDiagnosticHandler(severity)
  return function(_, button)
      if button == 'l' then
        local diagnosticConfig = { severity = severity, float = { border = "rounded" }}
        vim.diagnostic.goto_next(diagnosticConfig)
      else
        -- TODO Why need to delay?
        vim.defer_fn(function()
          fzf.diagnostic(severity)
        end, 200)
      end
  end
end

local function makeDiagnosticLabel(d)
  return function()
    local count = #diagnostic.get(0, { severity = d.level })
    if count > 0 then
      return (' %s %s'):format(d.icon, count)
    end
    return ''
  end
end

local menuName = 'statusline_list_files'
local M = {}

-- statusline配置
-- hlg highlight group
-- label (function|string) 显示内容
-- text (string) 纯文本显示内容
-- handler (function) 鼠标事件
M.leftList = {
  {
    hlg = hlgs.a.name,
    label = ' %-0.100F',
    handler = function(_, button, modifier)
      -- TODO: bugfix 文件跳转后会yank
      if button == 'r' then
        local files = vim.split(vim.fn.expand('*'), '\n')
        for _, f in pairs(files) do
          f = vim.fn.escape(f, '.')
          vim.cmd(('noremenu %s.%s :tabnew %s<cr>'):format(menuName, f, f))
        end
        vim.cmd('popu! ' .. menuName)
        vim.cmd('unmenu ' .. menuName)
        return
      end
      local fn = '%:p'
      modifier = vim.fn.trim(modifier)
      if modifier == '' then
        local gitroot = find_git_ancestor(vim.fn.expand('%:p'))
        local lspClients = vim.lsp.get_active_clients()
        local root = (lspClients and lspClients[1] and lspClients[1].config.root_dir) or gitroot
        if root then
          fn = fn .. string.format(':s?%s/??', root)
        end
      elseif modifier == 'c' then
        fn = '%'
      end
      require('util').copy(vim.fn.expand(fn))
    end,
  },
  {
    hlg = hlgs.aTob.name,
    text = '',
  },
  {
    hlg = hlgs.b.name,
    label = ' %l:%c '
  },
  {
    hlg = hlgs.bToc.name,
    text = ''
  },
  {
    hlg = diagnostics.error.hlg,
    handler = makeDiagnosticHandler(diagnostics.error.level),
    label = makeDiagnosticLabel(diagnostics.error),
  },
  {
    hlg = diagnostics.info.hlg,
    handler = makeDiagnosticHandler(diagnostics.info.level),
    label = makeDiagnosticLabel(diagnostics.info),
  },
  {
    hlg = diagnostics.warn.hlg,
    handler = makeDiagnosticHandler(diagnostics.warn.level),
    label = makeDiagnosticLabel(diagnostics.warn),
  },
}
M.rightList = {
  {
    hlg = hlgs.c.name,
    label = function()
      return gitsign() .. ' '
    end,
  },
  {
    hlg = hlgs.c.name,
    label = function()
      local ft = vim.o.ft
      if fileIcons[ft] then
        ft = fileIcons[ft]
      end
      return '[' .. ft .. ']'
    end,
  },
  {
    label = function()
      local icons = {
        unix = '',
        mac = '',
        dos = '',
      }
      return ' ' .. icons[o.fileformat] .. ' '
    end,
  },
  {
    hlg = hlgs.bToc.name,
    text = ''
  },
  {
    hlg = hlgs.b.name,
    label = ' %L '
  },
  {
    hlg = hlgs.aTob.name,
    text = ''
  },
  {
    hlg = hlgs.a.name,
    label = '%p%%%% '
  }
}

return M
