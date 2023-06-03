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
      vim.fn.timer_start(100, onExit)
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

local function setTmuxKeymap(key, opts)
  vim.keymap.set('n', key, function()
    tmux(opts)
  end, { buffer = 0 })
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

local function listBuffers()
  local bfs = vim.api.nvim_list_bufs()
  local input = {}
  for _, b in ipairs(bfs) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_name(b) ~= '' then
      local name = vim.api.nvim_buf_get_name(b)
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
  return input
end

vim.api.nvim_create_autocmd('BufReadPre', {
  pattern = '*',
  callback = function()
    local ft = vim.o.ft
    for _, v in pairs(ignoreFileTypes) do
      if v == ft then return end
    end

    -- 搜索文件内容
    setTmuxKeymap('<cr>f', {cmd = '_frg', output = true, callback = frgCb, root = true})
    setTmuxKeymap('<cr>F', {cmd = '_frg', output = true, callback = frgCb})

    -- 搜索文件名
    setTmuxKeymap('<cr>e', {cmd = '_fe', output = true, callback = fzfCb, root = true})
    setTmuxKeymap('<cr>E', {cmd = '_fe', output = true, callback = fzfCb})

    -- 搜索buffers
    setTmuxKeymap('<cr>b', {cmd = 'fzf', output = true, callback = function(output)
      for _, f in ipairs(output) do
        f = vim.fn.split(f, '\\s\\+')
        vim.cmd(string.format('tabnew +b%s', f[2]))
      end
    end, input = listBuffers})

    setTmuxKeymap('<cr>c', {cmd = 'fzf -m', output = true, callback = function(output)
      local buffers = vim.api.nvim_list_bufs()
      local selectedBuffers = {}
      for _, f in ipairs(output) do
        f = vim.fn.split(f, '\\s\\+')
        table.insert(selectedBuffers, vim.fn.bufnr(f[2]))
      end
      buffers = vim.tbl_filter(function(b)
        return vim.tbl_contains(selectedBuffers, b) == false
      end, buffers)
      vim.tbl_map(function(b)
        vim.api.nvim_buf_delete(b, {})
      end, buffers)
    end, input = listBuffers})

    vim.keymap.set('n', '<cr>s', ':set hls!<cr>', {buffer = 0})
  end
})

vim.api.nvim_create_autocmd('VimEnter', {
  pattern = '*',
  callback = function()
    -- TODO: 因为参数是[nvim, --embed]，所以长度为2。需优化判断
    if #vim.v.argv == 2 then
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
