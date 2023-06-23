local screenH = vim.o.lines
local screenW = vim.o.columns
local selectWinW = math.floor(screenW * 0.3)
local winH = math.floor(screenH * 0.8)
local previewWinW = math.floor(screenW * 0.5)
-- local top = math.floor((screenH - winH) * 0.5)
local top = 0
-- local selectWinleft = math.floor((screenW - selectWinW - previewWinW) * 0.5)
local selectWinleft = screenW - selectWinW - previewWinW - 3
local previewWinLeft = screenW - previewWinW
local debounce = require('util.debounce')

FzfPreviewCb = nil

local function remoteCmd(cmd)
  return string.format('node ~/.config/nvim/remote-cmd/index.js "%s"', cmd)
end

local shell_helper_path = vim.env.HOME .. '/.config/nvim/lua/self-plugin/fzf/shell_helper.lua'

local function rpcCmd(cmd)
  return ('nvim --clean -n --headless --cmd "lua loadfile([[%s]])().rpc_nvim_exec_lua([[$NVIM]], [[%s]])" {} {q} {n}'):format(shell_helper_path, cmd)
end

local fzfPreview = 'FzfPreview'
local fzfAccept = 'FzfAccept'
local fzfInputKey = 'fzfInput'
local fzfBind = 'FzfBind'
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
  local acceptCb = params.acceptCb
  local cwd = params.cwd
  local multi = params.multi
  local input = params.input
  local transform = params.transform
  local fzfInput

  if multi then
    cmd = cmd .. ' -m'
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
  local function getValue(fzfValue)
    fzfValue = string.gsub(fzfValue, "^'", "")
    fzfValue = string.gsub(fzfValue, "'$", "")
    if transform then
      local index = tonumber(string.match(fzfValue, '^%d+'))
      return input[index]
    else
      return fzfValue
    end
  end
  local bind = params.bind or {}

  local o = vim.deepcopy(options)
  local bindOption = vim.fn.join(vim.tbl_map(function(key)
    return string.format('%s:execute(%s)', key, remoteCmd(string.format('%s %s', fzfBind, key)))
  end, vim.tbl_keys(bind)), ',')
  if bindOption ~= '' then
    o.bind = bindOption
  end

  local selectBuf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_call(selectBuf, function()
    for k, v in pairs(o) do
      cmd = cmd .. string.format(" --%s='%s'", k, v)
    end
    cmd = cmd .. string.format(' | tr "\n" "\t" | xargs -I{} %s', remoteCmd(fzfAccept .. ' {}'))
    local termOptions = {env = env, cwd = cwd}
    if params.debug then
      termOptions.on_stdout = function(...) vim.print(...) end
    end
    vim.fn.termopen(cmd, termOptions)
  end)

  local selectWinId = vim.api.nvim_open_win(selectBuf, true,
    {relative = 'editor', row = top, col = selectWinleft, width = selectWinW, height = winH, border = 'rounded', title = ' results ', title_pos = 'center', style = 'minimal'}
  )

  local previewBuf = vim.api.nvim_create_buf(false, false)
  local previewWinId = vim.api.nvim_open_win(previewBuf, true,
    {relative = 'editor', row = top, col = previewWinLeft, width = previewWinW, height = winH, border = 'rounded', title = ' preview ', title_pos = 'center', style = 'minimal'}
  )

  FzfPreviewCb = debounce(function(args)
    if vim.api.nvim_win_is_valid(previewWinId) == false then
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
    vim.api.nvim_win_call(previewWinId, function()
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      local value = transform and input[index + 1] or selection[1]
      previewCb(value, ns, query)
      vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', win = previewWinId })
      vim.api.nvim_set_option_value('foldenable', false, { scope = 'local', win = previewWinId })
    end)
  end, 300)

  vim.api.nvim_create_user_command(fzfBind, function(args)
    local cb = bind[args.args]
    if cb then
      cb()
    end
  end, {nargs = 1})

  local function quit()
    vim.api.nvim_buf_clear_namespace(vim.fn.winbufnr(previewWinId), ns, 0, -1)
    vim.api.nvim_win_call(selectWinId, function()
      vim.cmd('quit')
    end)
    vim.api.nvim_win_call(previewWinId, function()
      vim.cmd('quit')
    end)
  end

  vim.api.nvim_create_user_command(fzfAccept, function(args)
    quit()
    local value = getValue(args.args)
    if multi then
      value = vim.split(value, '\t', {trimempty = true})
    end
    acceptCb(value)
    vim.api.nvim_del_user_command(fzfPreview)
    vim.api.nvim_del_user_command(fzfAccept)
  end, {nargs = 1})

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