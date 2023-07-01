local screenH = vim.o.lines
local screenW = vim.o.columns
local scale = 0.8
local top = 0
local debounce = require('util.debounce')

FzfPreviewCb = nil

local shell_helper_path = vim.env.HOME .. '/.config/nvim/lua/self-plugin/fzf/shell_helper.lua'

local function rpcCmd(cmd)
  return ('nvim --clean -n --headless --cmd "lua loadfile([[%s]])().rpc_nvim_exec_lua([[$NVIM]], [[%s]])" {} {q} {n}'):format(shell_helper_path, cmd)
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
  preview = rpcCmd('preview'),
  ['preview-window'] = 'right,0',
}

local M = {}
local ns = vim.api.nvim_create_namespace('fzf')

M.run = function(params)
  local cmd = params.cmd or 'fzf'
  local previewCb = params.previewCb
  local acceptCb = params.acceptCb or function() end
  local cwd = params.cwd
  local multi = params.multi
  local input = params.input
  local transform = params.transform
  local hidePreview = params.hidePreview or false
  local fzfInput
  local quitCb = params.quitCb
  local isVert = params.isVert ~= false
  scale = params.scale or 0.8

  if multi then
    cmd = cmd .. ' -m'
  end

  if params.history then
    cmd = cmd .. (' --history="$HOME/.fzf/history/%s"'):format(params.history)
  end

  -- Generate fzf input
  if transform then
    if input == nil then
      vim.notify('缺少input参数')
      return
    end
    fzfInput = {}
    for i, item in pairs(input) do
      table.insert(fzfInput, string.format('%s %s', i, transform(item)))
    end
  else
    fzfInput = input
  end
  local env = {[fzfInputKey] = ''}
  if fzfInput then
    env[fzfInputKey] = vim.fn.join(fzfInput, '\\n')
    cmd = string.format('echo -e $%s | %s', fzfInputKey, cmd)
  end

  local tmpfile = vim.fn.tempname()
  local o = vim.deepcopy(options)
  local selectBuf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_call(selectBuf, function()
    for k, v in pairs(o) do
      cmd = cmd .. string.format(" --%s='%s'", k, v)
    end
    local termOptions = {env = env, cwd = cwd}
    if params.debug then
      termOptions.on_stdout = function(...) vim.print(...) end
    end
    cmd = ('%s > %s'):format(cmd, tmpfile)
    vim.fn.termopen(cmd, termOptions)
  end)

  local selectLayout, previewLayout = getLayout(scale, hidePreview, isVert)
  local selectWinId = vim.api.nvim_open_win(selectBuf, true,
    makeFloatOpts({row = selectLayout.t, col = selectLayout.l, width = selectLayout.w, height = selectLayout.h, title = ' results '})
  )

  local statusline = (' FZF://%s'):format(params.cmd or 'fzf')
  vim.wo[selectWinId].statusline = statusline

  local previewBuf, previewWinId
  if hidePreview == false then
    previewBuf = vim.api.nvim_create_buf(false, false)
    previewWinId = vim.api.nvim_open_win(previewBuf, true,
      makeFloatOpts({row = previewLayout.t, col = previewLayout.l, width = previewLayout.w, height = previewLayout.h, title = ' preview '})
    )
    vim.wo[previewWinId].statusline = statusline
  end

  vim.keymap.set('t', '<c-c>', function()
    resize(0.1, selectWinId, previewWinId, hidePreview, isVert)
  end, {buffer = selectBuf})

  vim.keymap.set('t', '<c-q>', function()
    resize(-0.1, selectWinId, previewWinId, hidePreview, isVert)
  end, {buffer = selectBuf})

  FzfPreviewCb = debounce(function(args)
    if hidePreview == false and vim.api.nvim_win_is_valid(previewWinId) == false then
      return
    end
    if #args < 3 then
      return
    end
    local selection = {}
    local l = #args
    local index = args[l]
    local query = args[l - 1]
    for i = 1, l - 2 do
      table.insert(selection, args[i])
    end
    local cb = function()
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      local value = transform and input[index + 1] or selection[1]
      previewCb(value, ns, query)
      if hidePreview == false then
        vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', win = previewWinId })
        vim.api.nvim_set_option_value('number', true, { scope = 'local', win = previewWinId })
        vim.api.nvim_set_option_value('foldenable', false, { scope = 'local', win = previewWinId })
        -- after preview cb，may go to another file， need to update statusline option
        vim.wo[previewWinId].statusline = statusline
        vim.cmd('redraw')
      end
    end
    if hidePreview then
      cb()
    else
      vim.api.nvim_win_call(previewWinId, cb)
    end
  end, 300)

  local function quit()
    vim.api.nvim_buf_clear_namespace(vim.fn.winbufnr(previewWinId), ns, 0, -1)
    vim.api.nvim_win_call(selectWinId, function()
      vim.cmd('quit')
    end)
    if hidePreview == false then
      vim.api.nvim_win_call(previewWinId, function()
        vim.cmd('quit')
      end)
    end
    local results = vim.fn.readfile(tmpfile)
    if #results ~= 0 then
      vim.defer_fn(function()
        acceptCb(results)
      end, 0)
    end
    if quitCb then
      quitCb(ns)
    end
  end

  vim.api.nvim_create_autocmd('termclose', {
    callback = function()
      if vim.api.nvim_win_is_valid(selectWinId) then
        quit()
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
