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

local function remoteCmd(cmd)
  return string.format('node ~/.config/nvim/remote-cmd/index.js "%s"', cmd)
end

local fzfPreview = 'FzfPreview'
local fzfAccept = 'FzfAccept'
local fzfInputKey = 'fzfInput'
local fzfBind = 'FzfBind'
local options = {
  border = 'none',
  color = 'bg:-1',
  preview = remoteCmd(fzfPreview .. ' {}'),
  ['preview-window'] = 'right,0',
}

local m = {}
local ns = vim.api.nvim_create_namespace('fzf')

local run = function(params)
  local cmd = params.cmd or 'fzf'
  local previewCb = params.previewCb
  local acceptCb = params.acceptCb
  local cwd = params.cwd
  local input = params.input
  local transform = params.transform
  local fzfInput

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
    fzfValue = string.gsub(fzfValue, "'(.+)'", "%1")
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
    cmd = cmd .. string.format(' | xargs echo | xargs -I{} %s', remoteCmd(fzfAccept .. ' {}'))
    vim.fn.termopen(cmd, {env = env, cwd = cwd})
  end)

  local selectWinId = vim.api.nvim_open_win(selectBuf, true,
    {relative = 'editor', row = top, col = selectWinleft, width = selectWinW, height = winH, border = 'rounded', title = ' results ', title_pos = 'center', style = 'minimal'}
  )

  local previewBuf = vim.api.nvim_create_buf(false, false)
  local previewWinId = vim.api.nvim_open_win(previewBuf, true,
    {relative = 'editor', row = top, col = previewWinLeft, width = previewWinW, height = winH, border = 'rounded', title = ' preview ', title_pos = 'center', style = 'minimal'}
  )

  vim.api.nvim_create_user_command(fzfPreview, debounce(function(args)
    if vim.api.nvim_win_is_valid(previewWinId) == false then
      return
    end
    vim.api.nvim_win_call(previewWinId, function()
      vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
      previewCb(getValue(args.args), ns)
      vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', win = previewWinId })
      vim.api.nvim_set_option_value('foldenable', false, { scope = 'local', win = previewWinId })
    end)
  end, 300), {nargs = 1})

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
    acceptCb(getValue(args.args))
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

local previewFilter = {'png', 'jpg'}
local function findFile(cwd)
  run({
    cwd = cwd,
    cmd = 'fzf -m',
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
      args = vim.split(args, ' ')
      for _, f in ipairs(args) do
        vim.cmd(string.format('tabnew %s/%s', cwd, f))
      end
    end
  })
end
vim.keymap.set('n', '<c-f>O', function()
  findFile(vim.fn.getcwd())
end, {})
vim.keymap.set('n', '<c-f>o', function()
  findFile(require('lspconfig.util').root_pattern('package.json', '.git')(vim.fn.getcwd()))
end, {})

m.run = run
return m
