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

M.searchLines = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local buf = vim.api.nvim_get_current_buf()
  local input = {}
  for i, line in pairs(lines) do
    table.insert(input, ('%s %s'):format(i, line))
  end
  run({
    input = input,
    hidePreview = true,
    scale = 0.5,
    previewCb = function(args)
      local row = tonumber(args:match('^%d+'))
      vim.api.nvim_buf_call(buf, function()
        vim.fn.cursor({row, 1})
        vim.cmd('redraw')
      end)
    end
  })
end

M.oldFiles = function()
  run({
    input = vim.tbl_filter(function(f) return f:match('^term:') == nil end, vim.v.oldfiles),
    scale = 0.9,
    previewCb = function(args)
      previewer.file({fn = args})
    end,
    acceptCb = function(args)
      vim.print(args)
      vim.cmd(('tabnew %s'):format(args[1]))
    end
  })
end

return M
