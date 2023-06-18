local screenH = vim.o.lines
local screenW = vim.o.columns
local selectWinW = math.floor(screenW * 0.3)
local winH = math.floor(screenH * 0.5)
local previewWinW = math.floor(screenW * 0.5)
local top = math.floor((screenH - winH) * 0.5)
local selectWinleft = math.floor((screenW - selectWinW - previewWinW) * 0.5)
local previewWinLeft = selectWinleft + selectWinW + 2
local debounce = require('util.debounce')

local function remoteCmd(cmd)
  return string.format('node ~/.config/nvim/remote-cmd/index.js "%s"', cmd)
end

local fzfPreview = 'FzfPreview'
local fzfAccept = 'FzfAccept'
local options = {
  border = 'none',
  color = 'bg:-1',
  preview = remoteCmd(fzfPreview .. ' {1}'),
  ['preview-window'] = 'right,0',
}

local function fzfRun(params)
  local cmd = params.cmd or 'fzf'
  local previewCb = params.previewCb
  local acceptCb = params.acceptCb

  local selectBuf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_call(selectBuf, function()
    for k, v in pairs(options) do
      cmd = cmd .. string.format(" --%s='%s'", k, v)
    end
    cmd = cmd .. string.format(' | xargs -I{} %s', remoteCmd(fzfAccept .. ' {}'))
    vim.fn.termopen(cmd)
  end)

  local selectWinId = vim.api.nvim_open_win(selectBuf, true,
    {relative = 'editor', row = top, col = selectWinleft, width = selectWinW, height = winH, border = 'single', title = ' results ', title_pos = 'center', style = 'minimal'}
  )

  local previewBuf = vim.api.nvim_create_buf(false, false)
  local previewWinId = vim.api.nvim_open_win(previewBuf, true,
    {relative = 'editor', row = top, col = previewWinLeft, width = previewWinW, height = winH, border = 'single', title = ' preview ', title_pos = 'center', style = 'minimal'}
  )

  vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', win = previewWinId })

  vim.api.nvim_create_user_command(fzfPreview, debounce(function(args)
    vim.api.nvim_win_call(previewWinId, function()
      previewCb(args.args)
      vim.api.nvim_set_option_value('bufhidden', 'delete', { scope = 'local', win = previewWinId })
    end)
  end, 300), {nargs = 1})

  local function quit()
    vim.api.nvim_win_call(selectWinId, function()
      vim.cmd('quit')
    end)
    vim.api.nvim_win_call(previewWinId, function()
      vim.cmd('quit')
    end)
  end

  vim.api.nvim_create_user_command(fzfAccept, function(args)
    quit()
    acceptCb(args.args)
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

vim.keymap.set('n', '<leader>fo', function()
  local cwd = vim.fn.getcwd()
  fzfRun({
    previewCb = function(args)
      local fn = string.gsub(args, "'(.+)'", "%1")
      vim.cmd(string.format('edit %s/%s', cwd, fn))
    end,
    acceptCb = function(args)
      vim.cmd(string.format('tabnew %s/%s', cwd, args))
    end
  })
end, {})
