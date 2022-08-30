local ignoreFileTypes = {'qf', 'netrw'}
local function tmux(opts)
  local wholeCmd = 'tmux-window.sh'
  if opts.cmd then
    wholeCmd = wholeCmd .. ' -f "' .. opts.cmd .. '"'
  end
  local onExit
  if opts.callback then
    local outputFile = vim.fn.tempname()
    wholeCmd = wholeCmd .. ' -o ' .. outputFile
    onExit = function()
      if (vim.fn.filereadable(outputFile) ~= 0) then
        local output = vim.fn.readfile(outputFile)
        if (#output ~= 0) then
          opts.callback(output)
          return
        end
      end
      vim.fn.timer_start(500, onExit)
    end
  end
  if opts.root then
    wholeCmd = wholeCmd .. ' -r '
  end
  if opts.input then
    local inputFile = vim.fn.tempname()
    wholeCmd = wholeCmd .. ' -i ' .. inputFile
    local input = opts.input()
    vim.fn.writefile(input, inputFile)
  end
  vim.fn.jobstart(wholeCmd, {
    on_exit = onExit
  })
end

local function frgCb(output)
  for i, line in ipairs(output) do
    local _ = vim.fn.split(line, ':')
    vim.cmd(string.format('tabnew +call\\ cursor(%s,%s) %s', _[2], _[3], _[1]))
  end
end

local function fzfCb(output)
  for _, f in ipairs(output) do
    vim.cmd(string.format('tabnew %s', f))
  end
end

vim.api.nvim_create_autocmd('BufReadPre', {
  pattern = '*',
  callback = function()
    local ft = vim.o.ft
    for _, v in pairs(ignoreFileTypes) do
      if v == ft then return end
    end

    -- 搜索文件内容
    vim.keymap.set('n', '<cr>f', function()
      tmux({cmd = '_frg', output = true, callback = frgCb, root = true})
    end)
    vim.keymap.set('n', '<cr>F', function()
      tmux({cmd = '_frg', output = true, callback = frgCb})
    end)

    -- 搜索文件名
    vim.keymap.set('n', '<cr>e', function()
      tmux({cmd = '_fe', output = true, callback = fzfCb, root = true})
    end)
    vim.keymap.set('n', '<cr>E', function()
      tmux({cmd = '_fe', output = true, callback = fzfCb})
    end)

    -- 搜索buffers
    vim.keymap.set('n', '<cr>b', function()
      tmux({cmd = 'fzf', output = true, callback = function(output)
        for _, f in ipairs(output) do
          f = vim.fn.split(f, ' ')
          vim.cmd(string.format('tabnew +b%s', f[2]))
        end
      end, input = function()
        local bfs = vim.api.nvim_list_bufs()
        local input = {}
        for _, b in ipairs(bfs) do
          if vim.api.nvim_buf_is_loaded(b) then
            local name = vim.api.nvim_buf_get_name(b)
            if vim.fn.bufwinid(b) ~= -1 then
              name = '📝 ' .. name
            else
              if vim.fn.getbufinfo(b)[1].hidden == 0 then
                name = '🙈 ' .. name
              else
                name = '   ' .. name
              end
            end
            table.insert(input, name)
          end
        end
        return input
      end})
    end)

    vim.keymap.set('n', '<cr>s', ':set hls!<cr>', {buffer = 0})
  end
})

vim.api.nvim_create_autocmd('VimEnter', {
  pattern = '*',
  callback = function()
    if #vim.v.argv == 1 then
      tmux({cmd = 'fzf', output = true, input = function()
        return vim.v.oldfiles
      end, callback = function(output)
        for _, f in ipairs(output) do
          vim.cmd(string.format('e %s', f))
        end
      end})
    end
  end
})
