local screenH = vim.o.lines
local screenW = vim.o.columns
local scale = 0.8
local lastPosJump = require('base-config.lastPosJump')
local debounce = require('util.debounce')
local previewer = require('self-plugin.fzf.previewer')

FzfPreviewCb = nil

local shell_helper_path = vim.env.HOME .. '/.config/nvim/lua/self-plugin/fzf/shell_helper.lua'

local function rpcCmd(cmd, useText)
  local output = useText and '{}' or '{n} {+n}'
  return ('nvim --clean -n --headless --cmd "lua loadfile([[%s]])().rpc_nvim_exec_lua([[$NVIM]], [[%s]])" %s'):format(shell_helper_path, cmd, output)
end

local function highlight(previewWinId)
    local buf = vim.api.nvim_win_get_buf(previewWinId)
    local ft = vim.filetype.match({buf = buf})
    local useTreesitterHighlighter = false
    if ft then
      local lang = vim.treesitter.language.get_lang(ft)
      if vim.tbl_contains(require'nvim-treesitter.configs'.get_ensure_installed_parsers(), lang) then
        useTreesitterHighlighter = true
        vim.treesitter.start(buf, lang)
      end
    end
    if ft and useTreesitterHighlighter == false then
      vim.api.nvim_buf_set_option(buf, 'syntax', ft)
    end
end

local function wrapPreview(previewCb)
  local ei = vim.o.eventignore
  vim.o.eventignore = 'all'
  previewCb()
  vim.o.eventignore = ei
end

local function getLayout(s, hidePreview, isVert)
  if isVert then
    local previewWinW = 0
    local previewWinLeft
    local selectWinPercent = hidePreview and s or 0.4 * s
    local heightPercent = 1 * s
    local selectWinW = math.floor(screenW * selectWinPercent)
    local winH = math.floor(screenH * heightPercent)
    if hidePreview == false then
      local previewWinPercent = 0.6 * s
      previewWinW = math.floor(screenW * previewWinPercent)
      previewWinLeft = screenW - previewWinW
    end
    local selectWinleft = screenW - selectWinW - previewWinW - 4
    return {h = winH, l = selectWinleft, t = 0, w = selectWinW}, {h = winH, l = previewWinLeft, t = 0, w = previewWinW}
  else
    local previewWinH = 0
    local w = math.floor(screenW * scale)
    local selectWinH = math.floor(screenH * scale)
    local l = math.floor(screenW * (1 - s))
    local previewWinT
    if hidePreview == false then
      selectWinH = math.floor(screenH * scale * 0.5)
      previewWinT = selectWinH + 2
      previewWinH = selectWinH
    end
    return {h = selectWinH, w = w, l = l, t = 0}, {h = previewWinH, w = w, l = l, t = previewWinT}
  end
end

local floatOpts = {relative = 'editor', border = 'rounded', title_pos = 'center', style = 'minimal'}
local function makeFloatOpts(opts)
  return vim.tbl_extend('force', floatOpts, opts)
end

local maxScale = 0.9
local minScale = 0.5
local function resize(s, selectWinId, previewWinId, hidePreview, isVert)
  if s > 0 and scale >= maxScale then
    return
  end
  if s < 0 and scale <= minScale then
    return
  end
  scale = scale + s
  local selectLayout, previewLayout = getLayout(scale, hidePreview, isVert)
  vim.api.nvim_win_set_config(selectWinId, { relative = 'editor', row = selectLayout.t, col = selectLayout.l, width = selectLayout.w, height = selectLayout.h })
  vim.api.nvim_win_set_config(previewWinId, { relative = 'editor', row = previewLayout.t, col = previewLayout.l, width = previewLayout.w, height = previewLayout.h })
end

local fzfInputKey = 'fzfInput'
local options = {
  border = 'none',
  color = 'bg:-1',
  ['preview-window'] = 'right,0',
}

local M = {}
local ns = vim.api.nvim_create_namespace('fzf')

local function setStatuslineWin(currentWinId)
  vim.g.statuslineWinId = currentWinId
end
local function unsetStatuslineWin()
  vim.g.statuslineWinId = nil
end

M.run = function(params)
  local input = params.input
  if input and #input == 0 then
    return
  end
  local cmd = params.cmd or 'fzf'
  local previewCb = params.previewCb or function(value, ns) end
  local preparePreview = params.preparePreview
  local acceptCb = params.acceptCb or function(_) end
  local cwd = params.cwd
  local multi = params.multi
  local hidePreview = params.hidePreview or false
  local quitCb = params.quitCb
  local isVert = params.isVert
  local fzfInput = input
  local useText = input == nil
  local getPreviewTitle = params.getPreviewTitle
  local currentWinId = vim.api.nvim_get_current_win()
  setStatuslineWin(currentWinId)
  lastPosJump.clear()
  if input and type(input[1]) ~= 'string' then
    fzfInput = vim.tbl_map(function(item) return item.text end, input)
  end

  scale = params.scale or 0.8

  if multi then
    cmd = cmd .. ' -m'
  end

  if params.history then
    cmd = cmd .. (' --history="$HOME/.fzf/history/%s"'):format(params.history)
  end

  local env = {[fzfInputKey] = ''}
  if fzfInput then
    env[fzfInputKey] = vim.fn.join(fzfInput, '\\n')
    cmd = string.format('echo -e $%s | %s', fzfInputKey, cmd)
  end

  local tmpfile
  local o = vim.deepcopy(options)
  o.preview = rpcCmd('preview', useText)
  local selectBuf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_call(selectBuf, function()
    for k, v in pairs(o) do
      cmd = cmd .. string.format(" --%s='%s'", k, v)
    end
    local termOptions = {env = env, cwd = cwd}
    if params.debug then
      termOptions.on_stdout = function(...) vim.print(...) end
    end
    if useText then
      tmpfile = vim.fn.tempname()
      cmd = ('%s > %s'):format(cmd, tmpfile)
    end
    vim.fn.termopen(cmd, termOptions)
  end)

  local selectLayout, previewLayout = getLayout(scale, hidePreview, isVert)
  local selectWinId = vim.api.nvim_open_win(selectBuf, true,
    makeFloatOpts({row = selectLayout.t, col = selectLayout.l, width = selectLayout.w, height = selectLayout.h, title = ' results '})
  )

  local previewBuf, previewWinId
  if hidePreview == false then
    previewBuf = vim.api.nvim_create_buf(false, false)
    previewWinId = vim.api.nvim_open_win(previewBuf, true,
      makeFloatOpts({row = previewLayout.t, col = previewLayout.l, width = previewLayout.w, height = previewLayout.h, title = ' preview '})
    )
  end

  vim.keymap.set('t', '<c-c>', function()
    resize(0.1, selectWinId, previewWinId, hidePreview, isVert)
  end, {buffer = selectBuf})

  vim.keymap.set('t', '<c-q>', function()
    resize(-0.1, selectWinId, previewWinId, hidePreview, isVert)
  end, {buffer = selectBuf})

  local currentPreview
  vim.keymap.set('t', '<c-y>', function()
    acceptCb(multi and {currentPreview} or currentPreview)
  end, {buffer = selectBuf})
  vim.api.nvim_create_autocmd({'WinEnter'}, {
    buffer = selectBuf,
    callback = function()
      setStatuslineWin(currentWinId)
      vim.cmd('startinsert')
    end
  })
  vim.api.nvim_create_autocmd({'WinLeave'}, {
    buffer = selectBuf,
    callback = function()
      -- 不知道为啥预览打开时，先触发WinLeave，然后再触发WinEnter
      -- 导致statuslineWinId又设置了，所以延后执行
      vim.defer_fn(function()
        unsetStatuslineWin()
      end, 0)
    end
  })

  local results = {}
  FzfPreviewCb = debounce(function(args)
    if hidePreview == false and vim.api.nvim_win_is_valid(previewWinId) == false then
      return
    end
    local value = args[1]
    if useText == false then
      value = input[args[1] + 1]
      results = vim.fn.slice(args, 1)
    end
    currentPreview = value
    local cb = function()
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      local needEvent = false
      if preparePreview then
        local opts = preparePreview(value)
        if opts.fn and (opts.fn:match('^man://') or vim.fn.isdirectory(opts.fn) == 1) then
          needEvent = true
        end
        local function cb()
          if opts.fn or opts.buf then
            opts.ns = ns
            previewer.file(opts)
          end
        end
        if needEvent then
          cb()
        else
          wrapPreview(cb)
        end
      else
        wrapPreview(function()
          previewCb(value, ns)
        end)
      end
      if needEvent == false then
        highlight(previewWinId)
      end
      if hidePreview == false then
        vim.api.nvim_set_option_value('bufhidden', 'wipe', { scope = 'local', win = previewWinId })
        vim.api.nvim_set_option_value('number', true, { scope = 'local', win = previewWinId })
        vim.api.nvim_set_option_value('foldenable', false, { scope = 'local', win = previewWinId })
        if getPreviewTitle then
          vim.api.nvim_win_set_config(previewWinId, { title = getPreviewTitle(value)})
        end
      end
    end
    if hidePreview then
      cb()
    else
      vim.api.nvim_win_call(previewWinId, cb)
    end
  end, 50)

  local function quit(status)
    unsetStatuslineWin()
    vim.api.nvim_buf_clear_namespace(vim.fn.winbufnr(previewWinId), ns, 0, -1)
    vim.api.nvim_win_call(selectWinId, function()
      vim.cmd('quit')
    end)
    if hidePreview == false then
      vim.api.nvim_win_call(previewWinId, function()
        vim.cmd('quit')
      end)
    end
    vim.api.nvim_set_current_win(currentWinId)
    if useText then
      results = vim.fn.readfile(tmpfile)
    else
      results = vim.tbl_map(function(i) return input[tonumber(i) + 1] end, results)
    end
    if status == 0 and #results ~= 0 then
      vim.defer_fn(function()
        lastPosJump.autocmd()
        acceptCb(multi and results or results[1])
      end, 0)
    end
    if quitCb then
      quitCb(ns)
    end
  end

  vim.api.nvim_create_autocmd('termclose', {
    callback = function()
      if vim.api.nvim_win_is_valid(selectWinId) then
        quit(vim.v.event.status)
      end
    end
  })

  vim.defer_fn(function()
    vim.api.nvim_set_current_win(selectWinId)
    vim.api.nvim_buf_call(selectBuf, function()
      vim.cmd('normal i')
    end)
  end, 0)
end

return M
