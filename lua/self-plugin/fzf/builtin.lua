local run = require('self-plugin.fzf').run
local previewer = require('self-plugin.fzf.previewer')

local previewFilter = {'png', 'jpg'}
local M = {}

M.findFile = function (cwd)
  run({
    cwd = cwd,
    multi = true,
    history = 'fe',
    getPreviewTitle = function(args)
      return string.format('%s/%s', cwd, args)
    end,
    previewCb = function(args)
      local fn = string.format('%s/%s', cwd, args)
      if #vim.tbl_filter(function(p)
        return string.match(fn, p)
      end, previewFilter) > 0 then
        return
      end
      vim.cmd(string.format('edit %s', fn))
    end,
    acceptCb = function(args)
      for _, f in ipairs(args) do
        vim.cmd(string.format('tabnew %s/%s', cwd, f))
      end
    end
  })
end

M.rgSearch = function(cwd)
  local RG_PREFIX="rg"
  local cmd = string.format('%s "" | fzf -0 -1 --exact --delimiter : --nth=3.. -m --bind "change:reload(%s {q})" --ansi --phony', RG_PREFIX, RG_PREFIX)
  local function getValue(args)
    local fn, row, col =  string.match(args, '^([^:]*):(%d+):(%d+)')
    fn = string.format('%s/%s', cwd, fn)
    return fn, row - 1, col - 1
  end
  run({
    cmd = cmd,
    cwd = cwd,
    multi = true,
    history = 'frg',
    getPreviewTitle = function(args)
      return getValue(args)
    end,
    previewCb = function(args, ns)
      local fn, row, col = getValue(args)
      previewer.file({fn = fn, row = row, col = col, ns = ns, hlCol = true, hlRow = true})
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
    multi = true,
    previewCb = function(args)
      previewer.file({fn = args})
    end,
    acceptCb = function(args)
      vim.cmd(('edit %s'):format(args[1]))
      if #args > 1 then
        for i = 2, #args do
          vim.cmd(('tabnew %s'):format(args[i]))
        end
      end
    end
  })
end

local listBuffers = function(cb)
  local bfs = vim.api.nvim_list_bufs()
  local input = {}
  for _, b in ipairs(bfs) do
    local name = vim.api.nvim_buf_get_name(b)
    if vim.api.nvim_buf_is_loaded(b) and name ~= '' and name:match('^term://') == nil then
      if vim.fn.bufwinid(b) ~= -1 then
        name = '📝 ' .. name
      else
        if vim.fn.getbufinfo(b)[1].hidden == 0 then
          name = '🙈 ' .. name
        else
          name = 'h  ' .. name
        end
      end
      table.insert(input, name)
    end
  end
  run({
    input = input,
    multi = true,
    previewCb = function(args)
      previewer.file({fn = vim.split(args, '%s')[2]})
    end,
    acceptCb = cb
  })
end

M.buffers = function()
  listBuffers(function(args)
    args = vim.tbl_map(function(_)
      return vim.split(_, '%s+')[2]
    end, args)
    for _, f in pairs(args) do
      vim.cmd(('tabnew %s'):format(f))
    end
  end)
end

M.clearBuffer = function()
  listBuffers(function(args)
    local buffers = vim.api.nvim_list_bufs()
    local selectedBuffers = {}
    for _, f in ipairs(args) do
      f = vim.fn.split(f, '\\s\\+')
      table.insert(selectedBuffers, vim.fn.bufnr(f[2]))
    end
    buffers = vim.tbl_filter(function(b)
      return vim.tbl_contains(selectedBuffers, b) == false
    end, buffers)
    vim.tbl_map(function(b)
      vim.api.nvim_buf_delete(b, {})
    end, buffers)
  end)
end

M.jumps = function()
  local output = vim.api.nvim_exec2('jumps', {output = true})
  local jumps = vim.split(output.output, '\n')
  local jumpList, pos = unpack(vim.fn.getjumplist())
  local l = #jumpList
  if l == 0 then
    vim.notify('No jumps')
    return
  end
  local input = {}
  for i, j in pairs(jumpList) do
    table.insert(input, {text = jumps[i + 1]:match('^>?%s*%d+(.*)'), info = j})
  end
  run({
    cmd = ('fzf --tac --no-sort --bind="load:pos(%s)"'):format(l - pos),
    input = input,
    getPreviewTitle = function(args)
      return vim.api.nvim_buf_get_name(args.info.bufnr)
    end,
    previewCb = function(args, ns)
      local info = args.info
      previewer.file({buf = info.bufnr, row = info.lnum - 1, col = info.col, hlRow = true, hlCol = true, ns = ns})
    end,
    acceptCb = function(args)
      local info = args.info
      vim.cmd(('tab sb %s'):format(info.bufnr))
      vim.fn.cursor({info.lnum, info.col + 1})
    end
  })
end

M.changes = function()
  local output = vim.api.nvim_exec2('changes', {output = true})
  local changes = vim.split(output.output, '\n')
  local changeList, pos = unpack(vim.fn.getchangelist())
  local l = #changeList
  if l == 0 then
    vim.notify('No changes')
    return
  end
  local input = {}
  for i, j in pairs(changeList) do
    table.insert(input, {text = changes[i + 1]:match('^>?%s*%d+(.*)'), info = j})
  end
  local buf = vim.api.nvim_get_current_buf()
  run({
    cmd = ('fzf --tac --no-sort --bind="load:pos(%s)"'):format(l - pos),
    input = input,
    hidePreview = true,
    scale = 0.4,
    previewCb = function(args)
      local info = args.info
      vim.api.nvim_buf_call(buf, function()
        vim.fn.cursor({info.lnum, info.col})
        vim.cmd('redraw')
      end)
    end,
    acceptCb = function(args)
      local info = args.info
      vim.fn.cursor({info.lnum, info.col})
    end
  })
end

M.nvimApis = function()
  local keys = vim.tbl_keys(vim.api)
  run({
    input = keys,
    scale = 0.5,
    isVert = true,
    previewCb = function(args)
      vim.api.nvim_win_call(0, function()
        vim.bo.buftype = 'help'
        vim.cmd('help ' .. args)
      end)
    end,
    acceptCb = function(args)
      vim.cmd('help ' .. args)
    end
  })
end

return M
