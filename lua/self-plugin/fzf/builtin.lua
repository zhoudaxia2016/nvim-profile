local run = require('self-plugin.fzf.init').run
local previewer = require('self-plugin.fzf.previewer')

local previewFilter = {'png', 'jpg'}
local M = {}

M.findFile = function (cwd)
  run({
    cwd = cwd,
    multi = true,
    previewCb = function(args)
      local fn = string.format('%s/%s', cwd, args)
      if #vim.tbl_filter(function(p)
        return string.match(fn, p)
      end, previewFilter) > 0 then
        return
      end
      vim.cmd(string.format('edit %s', fn))
      vim.wo.winbar = fn
    end,
    acceptCb = function(args)
      for _, f in ipairs(args) do
        vim.cmd(string.format('tabnew %s/%s', cwd, f))
      end
    end
  })
end

M.rgSearch = function(cwd)
  local RG_PREFIX="rg --column --line-number --no-heading --color=always -S --type-add 'tsx:*.tsx' --type-add 'test:*.test.*'"
  local cmd = string.format('%s "" | fzf -0 -1 --exact --delimiter : --nth=3.. -m --history="$HOME/.fzf/history/frg" --bind "change:reload(%s {q})" --ansi --phony', RG_PREFIX, RG_PREFIX)
  local function getValue(args)
    local fn, row, col =  string.match(args, '^([^:]*):(%d+):(%d+)')
    fn = string.format('%s/%s', cwd, fn)
    return fn, row - 1, col - 1
  end
  run({
    cmd = cmd,
    cwd = cwd,
    multi = true,
    previewCb = function(args, ns, query)
      local fn, row, col = getValue(args)
      previewer.file({fn = fn, row = row, col = col})
      vim.highlight.range(0, ns, 'Todo', {row, col}, {row, col + #query}, {priority = 9999})
    end,
    acceptCb = function(args)
      for _, f in ipairs(args) do
        local fn, row, col = getValue(f)
        vim.cmd(string.format('tabnew +%s %s | normal %sl', row + 1, fn, col))
      end
    end
  })
end

return M
