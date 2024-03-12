local run = require('self-plugin.fzf').run
local palettes = require('nord.named_colors')
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
    preparePreview = function(args)
      local fn = string.format('%s/%s', cwd, args)
      if #vim.tbl_filter(function(p)
        return string.match(fn, p)
      end, previewFilter) > 0 then
        return
      end
      return {fn = fn}
    end,
    acceptCb = function(args)
      for _, f in ipairs(args) do
        vim.cmd(string.format('tab drop %s/%s', cwd, f))
      end
    end
  })
end

M.rgSearch = function(cwd, moreOpts)
  moreOpts = moreOpts or ''
  local RG_PREFIX="rg " .. moreOpts
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
    preparePreview = function(args)
      local fn, row, col = getValue(args)
      return {fn = fn, row = row, col = col, hlCol = true, hlRow = true}
    end,
    acceptCb = function(args)
      for _, f in ipairs(args) do
        local fn, row, col = getValue(f)
        vim.cmd(string.format('tab drop +%s %s | normal %sl', row + 1, fn, col))
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
    getPreviewTitle = function(args)
      return args
    end,
    preparePreview = function(args)
      return {fn = args}
    end,
    acceptCb = function(args)
      vim.cmd(('edit %s'):format(args[1]))
      if #args > 1 then
        for i = 2, #args do
          vim.cmd(('tab drop %s'):format(args[i]))
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
    preparePreview = function(args)
      return {fn = vim.split(args, '%s')[2]}
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
      vim.cmd(('tab drop %s'):format(f))
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
    preparePreview = function(args)
      local info = args.info
      return {buf = info.bufnr, row = info.lnum - 1, col = info.col, hlRow = true, hlCol = true}
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

M.diagnostic = function(severity)
  local diagnostic = vim.diagnostic.get(0, {severity = severity})
  if (#diagnostic == 0) then
    return
  end
  if #diagnostic == 1 then
    vim.fn.cursor({diagnostic[1].lnum + 1, diagnostic[1].col + 1})
    return
  end
  local input = vim.tbl_map(function(_)
    return vim.tbl_extend('force', _, {text = ('%s|%s'):format(vim.fn.getline(_.lnum + 1), _.message)})
  end, diagnostic)
  local buf = vim.api.nvim_get_current_buf()
  run({
    input = input,
    hidePreview = true,
    scale = 0.5,
    previewCb = function(args)
      vim.api.nvim_buf_call(buf, function()
        vim.fn.cursor({args.lnum + 1, args.col + 1})
        vim.cmd('normal zz')
      end)
    end,
  })
end

M.z = function()
  local root = require('util').getRoot()
  run({
    cwd = root,
    cmd = 'source ~/.bashrc;_z -c -l 2>&1 | fzf +s --tac --with-nth=2',
    hidePreview = true,
    scale = 0.6,
    acceptCb = function(args)
      vim.cmd(('tab drop %s'):format(vim.split(args, '%s+')[2]))
    end,
  })
end

local function hex2rgb(hex)
    hex = hex:gsub("#","")
    return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
end

local function format(color, str)
  local r, g, b = hex2rgb(color)
  return string.format('\\e[38;2;%s;%s;%sm%s\\e[0m', r, g, b, str)
end

M.keymaps = function()
  local modes = {'n', 'i', 'v', 's', 'o', 'c', 't'}
  local keymaps = {}
  for _, m in pairs(modes)do
    keymaps = vim.list_extend(keymaps, vim.api.nvim_get_keymap(m))
  end
  keymaps = vim.tbl_map(function(keymap)
    local rhs = keymap.callback and debug.getinfo(keymap.callback).short_src or keymap.rhs
    rhs = format(palettes.blue, rhs)
    local lhs = format(palettes.purple, keymap.lhs)
    local desc = keymap.desc or ''
    local info = {
      info = keymap,
      text = string.format('%s\\t%s\\t%s', keymap.mode, lhs, desc)
    }
    return info
  end, keymaps)
  run({
    input = keymaps,
    align = true,
    getPreviewTitle = function(args)
      if args.info.callback then
        local callbackInfo = debug.getinfo(args.info.callback)
        return callbackInfo.short_src
      end
      return 'String Keymap'
    end,
    previewCb = function(args, ns)
      if args.info.callback then
        local callbackInfo = debug.getinfo(args.info.callback)
        local row = callbackInfo.linedefined
        previewer.file({
          fn = callbackInfo.short_src,
          row = row,
          col = 1,
          ns = ns,
          selection = {
            startRange = {line = row - 1, character = 1},
            endRange = {line = callbackInfo.lastlinedefined - 1, character = -1},
          }
        })
      else
        previewer.string(args.info.rhs)
      end
    end,
    acceptCb = function(args)
      if args.info.callback then
        local callbackInfo = debug.getinfo(args.info.callback)
        local row = callbackInfo.linedefined
        vim.cmd(string.format('tab drop +%s %s | normal %sl', row, callbackInfo.short_src, 0))
      end
    end
  })
end

return M
