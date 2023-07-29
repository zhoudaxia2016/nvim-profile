local run = require('self-plugin.fzf').run

vim.api.nvim_create_user_command('FzfDebugVim', function()
  vim.cmd('packadd termdebug')
  run({
    cmd = [[ps --no-header ax -o "pid,cmd" | awk  '$2=="nvim" && $3 == "--embed"' | fzf]],
    hidePreview = true,
    acceptCb = function(args)
      args = vim.split(args, '%s+', {trimempty = true})[1]
      vim.cmd(('Termdebug nvim %s'):format(args))
    end,
  })
end, {})

vim.g.termdebug_useFloatingHover = 0

local keymap_builtin = {
  b = 'Break',
  c = 'Clear',
  ['8'] = 'Continue',
  ['0'] = 'Over',
  ['-'] = 'Step',
  u = 'Until',
  ['_'] = 'Finish',
  e = 'Evaluate',
}

local keymap = {
  p = 'up',
  n = 'down',
  q = function()
    vim.ui.input({prompt = 'Condition: '}, function(input)
      local fn = vim.fn.expand('%:p')
      local line = vim.fn.line('.')
      vim.fn.TermDebugSendCommand(('break %s:%s if %s'):format(fn, line, input))
    end)
  end,
}

for k, c in pairs(keymap_builtin) do
  vim.keymap.set('n', '<m-l>' .. k, function()
    vim.cmd(c)
  end)
end

for k, c in pairs(keymap) do
  vim.keymap.set('n', '<m-l>' .. k, function()
    if type(c) == 'function' then
      c()
    else
      vim.fn.TermDebugSendCommand(c)
    end
  end)
end
