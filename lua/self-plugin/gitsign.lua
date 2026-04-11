local gitsign_data = {}
local preview_ns = vim.api.nvim_create_namespace('gitsign_preview')
local preview_state = {}
local preview_ticket = {}
local origin_buf_cache = {}
local PREVIEW_DELETE_HL = 'DiffDelete'
local PREVIEW_ADD_HL = 'DiffAdd'
local gitsign_config = {
  a = { hl = 'diffAdded', icon = '│' },
  db = { hl = 'diffRemoved', icon = '‾'},
  dn = { hl = 'diffRemoved', icon = '_' },
  c = { hl = 'diffChanged', icon = '│' },
  cd = { hl = 'diffChanged', icon = '~' },
}

local function getCurrentFileContext()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then
    return nil
  end
  if file:match('^%a+://') then
    return nil
  end
  if vim.bo.buftype ~= '' then
    return nil
  end
  return {
    dir = vim.fs.dirname(file),
    name = vim.fs.basename(file),
  }
end

local function execute(cmd, cwd)
  local result = vim.system(cmd, { text = true, cwd = cwd }):wait()
  return result.code, result.stdout or '', result.stderr or ''
end

local function memoize(fn, hash_fn)
  local cache = setmetatable({}, { __mode = 'kv' }) ---@type table<any,any>

  return function(...)
    local key = hash_fn(...)
    if cache[key] == nil then
      local v = fn(...) ---@type any
      cache[key] = v ~= nil and v or vim.NIL
    end

    local v = cache[key]
    return v ~= vim.NIL and v or nil
  end
end

local isInsideGitWorkTree = memoize(function(_)
  local context = getCurrentFileContext()
  if context == nil then
    return false
  end

  local code, stdout = execute({ 'git', 'rev-parse', '--is-inside-work-tree' }, context.dir)
  local res = code == 0 and vim.trim(stdout) == 'true'
  if (res == true) then
    local ignoreCode = execute({ 'git', 'check-ignore', context.name }, context.dir)
    return ignoreCode ~= 0
  end
  return res
end, function(buf)
  return tostring(buf)
end)

local function getDiff()
  local context = getCurrentFileContext()
  if context == nil then
    return {}
  end
  local code, originFile = execute({ 'git', 'show', '--no-color', ':./' .. context.name }, context.dir)
  if code ~= 0 then
    return {}
  end
  return vim.diff(originFile,
    vim.fn.join(vim.api.nvim_buf_get_lines(0, 0, -1, true), '\n'),
    { linematch = true, result_type = 'indices', ignore_whitespace_change_at_eol = true }
  )
end

local function splitLines(text)
  return vim.split(text, '\n', { plain = true })
end

local function getOriginLines()
  local context = getCurrentFileContext()
  if context == nil then
    return nil, 'No file in current buffer'
  end

  local code, stdout, stderr = execute({ 'git', 'show', '--no-color', ':./' .. context.name }, context.dir)
  if code ~= 0 then
    return nil, vim.trim(stderr ~= '' and stderr or stdout)
  end

  return splitLines(stdout)
end

local function invalidateOriginBuf(buf)
  local item = origin_buf_cache[buf]
  if item ~= nil and item.buf ~= nil and vim.api.nvim_buf_is_valid(item.buf) then
    vim.api.nvim_buf_delete(item.buf, { force = true })
  end
  origin_buf_cache[buf] = nil
end

local function getCurrentHunk()
  local lineNum = vim.api.nvim_win_get_cursor(0)[1]
  for _, chunk in ipairs(getDiff()) do
    local newStart = chunk[3]
    local newCount = chunk[4]
    if newCount == 0 then
      local anchor = math.max(1, newStart)
      if lineNum == anchor or lineNum == anchor + 1 then
        return chunk
      end
    else
      local newEnd = newStart + newCount - 1
      if lineNum >= newStart and lineNum <= newEnd then
        return chunk
      end
    end
  end
  return nil
end

local function getSyntaxGroup(scratchBuf, row, col)
  local ok, captures = pcall(vim.treesitter.get_captures_at_pos, scratchBuf, row - 1, col)
  if ok and captures ~= nil then
    for i = #captures, 1, -1 do
      local cap = captures[i]
      local capName = cap.capture or ''
      if capName ~= '' then
        local base = capName:sub(1, 1) == '@' and capName or ('@' .. capName)
        if cap.lang ~= nil and cap.lang ~= '' and not base:match('%.' .. cap.lang .. '$') then
          return base .. '.' .. cap.lang
        end
        return base
      end
    end
  end

  return 'Normal'
end

local function pickStableGroup(scratchBuf, row, col, fallback)
  local hl = getSyntaxGroup(scratchBuf, row, col)
  if hl ~= nil and hl ~= '' then
    return hl
  end
  if fallback ~= nil then
    return fallback
  end
  if col > 0 then
    hl = getSyntaxGroup(scratchBuf, row, col - 1)
    if hl ~= nil and hl ~= '' then
      return hl
    end
  end
  hl = getSyntaxGroup(scratchBuf, row, col + 1)
  if hl ~= nil and hl ~= '' then
    return hl
  end
  return 'Normal'
end

local function getLineChunks(line, scratchBuf, row, bgHl)
  local chunks = {}
  if line == '' then
    return { { ' ', bgHl } }
  end

  local startCol = 1
  local currentHl = pickStableGroup(scratchBuf, row, 0)
  for col = 1, #line - 1 do
    local hl = pickStableGroup(scratchBuf, row, col, currentHl)
    if hl ~= currentHl then
      table.insert(chunks, {
        line:sub(startCol, col),
        { currentHl, bgHl },
      })
      startCol = col + 1
      currentHl = hl
    end
  end
  table.insert(chunks, {
    line:sub(startCol, #line),
    { currentHl, bgHl },
  })
  return chunks
end

local function splitTextByWidth(text, maxWidth)
  local charCount = vim.fn.strchars(text)
  if charCount == 0 then
    return '', ''
  end

  local lo = 1
  local hi = charCount
  local best = 0
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    local candidate = vim.fn.strcharpart(text, 0, mid)
    local width = vim.fn.strdisplaywidth(candidate)
    if width <= maxWidth then
      best = mid
      lo = mid + 1
    else
      hi = mid - 1
    end
  end

  if best == 0 then
    local head = vim.fn.strcharpart(text, 0, 1)
    local tail = vim.fn.strcharpart(text, 1, math.max(charCount - 1, 0))
    return head, tail
  end

  local head = vim.fn.strcharpart(text, 0, best)
  local tail = vim.fn.strcharpart(text, best, math.max(charCount - best, 0))
  return head, tail
end

local function padLine(line, targetWidth, bgHl)
  local width = 0
  for _, chunk in ipairs(line) do
    width = width + vim.fn.strdisplaywidth(chunk[1])
  end
  local padWidth = math.max(targetWidth - width, 0)
  if padWidth > 0 then
    table.insert(line, { string.rep(' ', padWidth), bgHl })
  end
  return line
end

local function wrapLineChunks(lineChunks, maxWidth, bgHl)
  local wrapped = {}
  local currentLine = {}
  local currentWidth = 0
  local targetWidth = math.max(maxWidth or 1, 1)

  local function pushCurrentLine()
    if #currentLine > 0 then
      table.insert(wrapped, padLine(currentLine, targetWidth, bgHl))
      currentLine = {}
      currentWidth = 0
    end
  end

  for _, chunk in ipairs(lineChunks) do
    local text = chunk[1]
    local hl = chunk[2]
    local textWidth = vim.fn.strdisplaywidth(text)
    if textWidth == 0 then
      table.insert(currentLine, { text, hl })
    else
      local remainingText = text
      while remainingText ~= '' do
        local remainingWidth = targetWidth - currentWidth
        if remainingWidth <= 0 then
          pushCurrentLine()
          remainingWidth = targetWidth
        end

        local piece, tail = splitTextByWidth(remainingText, remainingWidth)
        if piece == '' then
          pushCurrentLine()
        else
          table.insert(currentLine, { piece, hl })
          currentWidth = currentWidth + vim.fn.strdisplaywidth(piece)
          remainingText = tail
          if currentWidth >= targetWidth then
            pushCurrentLine()
          end
        end
      end
    end
  end

  pushCurrentLine()
  return wrapped
end

local function makeScratchBuf(lines, filetype)
  local scratchBuf = vim.api.nvim_create_buf(false, true)
  vim.bo[scratchBuf].bufhidden = 'wipe'
  vim.bo[scratchBuf].buftype = 'nofile'
  vim.bo[scratchBuf].swapfile = false
  vim.bo[scratchBuf].modifiable = true
  vim.bo[scratchBuf].filetype = filetype
  vim.api.nvim_buf_set_lines(scratchBuf, 0, -1, false, lines)
  local lang = vim.treesitter.language.get_lang(filetype) or filetype
  pcall(function()
    vim.treesitter.get_parser(scratchBuf, lang):parse()
  end)
  pcall(vim.treesitter.start, scratchBuf, lang)
  return scratchBuf
end

local function getOriginScratchBuf(buf, lines, filetype)
  local key = table.concat(lines, '\n')
  local cached = origin_buf_cache[buf]
  if cached ~= nil and cached.key == key and cached.filetype == filetype and vim.api.nvim_buf_is_valid(cached.buf) then
    return cached.buf
  end

  invalidateOriginBuf(buf)
  local scratchBuf = makeScratchBuf(lines, filetype)
  origin_buf_cache[buf] = {
    key = key,
    filetype = filetype,
    buf = scratchBuf,
  }
  return scratchBuf
end

local function clearPreview(buf)
  vim.api.nvim_buf_clear_namespace(buf, preview_ns, 0, -1)
  preview_state[buf] = nil
  preview_ticket[buf] = (preview_ticket[buf] or 0) + 1
end

local function sameHunk(a, b)
  if a == nil or b == nil then
    return false
  end

  return a[1] == b[1]
    and a[2] == b[2]
    and a[3] == b[3]
    and a[4] == b[4]
end

local function addLineHighlights(buf, startLine, count, hl)
  if count == 0 then
    return
  end

  for i = startLine, startLine + count - 1 do
    vim.api.nvim_buf_set_extmark(buf, preview_ns, i - 1, 0, {
      line_hl_group = hl,
      hl_eol = true,
    })
  end
end

local m = {}

m.sign = function()
  local lnum = vim.v.lnum
  local buf = vim.api.nvim_get_current_buf()
  if (isInsideGitWorkTree(buf) == false) then
    return ''
  end
  if (gitsign_data[buf]) then
    local status = gitsign_data[buf][lnum]
    local config = status and gitsign_config[status]
    if config ~= nil then
      return string.format('%%#%s#%s', config.hl, config.icon)
    end
  end
  return ' '
end

m.open_diff = function()
  local buf = vim.api.nvim_get_current_buf()
  local hunk = getCurrentHunk()
  if hunk == nil then
    vim.notify('No diff hunk at cursor', vim.log.levels.INFO)
    return
  end

  if sameHunk(preview_state[buf], hunk) then
    clearPreview(buf)
    return
  end

  local originLines, err = getOriginLines()
  if originLines == nil then
    vim.notify(err, vim.log.levels.INFO)
    return
  end

  local anchor = math.max(0, hunk[3] - 1)
  local filetype = vim.bo.filetype
  clearPreview(buf)
  local ticket = preview_ticket[buf] or 0
  local scratchBuf = getOriginScratchBuf(buf, originLines, filetype)
  local parser = vim.treesitter.get_parser(scratchBuf, vim.treesitter.language.get_lang(filetype) or filetype)
  parser:parse(nil, vim.schedule_wrap(function()
    if vim.api.nvim_buf_is_valid(buf) == false then
      return
    end
    if (preview_ticket[buf] or 0) ~= ticket then
      return
    end

    local oldLines = {}
    if hunk[2] > 0 then
      for i = 0, hunk[2] - 1 do
        local line = originLines[hunk[1] + i] or ''
        table.insert(oldLines, line)
      end
    end
    local virtLines = {}
    local windowWidth = math.max(vim.api.nvim_win_get_width(0), 1)
    for i, line in ipairs(oldLines) do
      local row = hunk[1] + i - 1
      local chunks = getLineChunks(line, scratchBuf, row, PREVIEW_DELETE_HL)
      local wrapped = wrapLineChunks(chunks, windowWidth, PREVIEW_DELETE_HL)
      for _, virtLine in ipairs(wrapped) do
        table.insert(virtLines, virtLine)
      end
    end

    if #virtLines > 0 then
      vim.api.nvim_buf_set_extmark(buf, preview_ns, anchor, 0, {
        virt_lines = virtLines,
        virt_lines_above = hunk[4] ~= 0,
        hl_mode = 'combine',
      })
    end
    if hunk[4] > 0 then
      addLineHighlights(buf, hunk[3], hunk[4], PREVIEW_ADD_HL)
    end
    preview_state[buf] = { hunk[1], hunk[2], hunk[3], hunk[4] }
  end))
end

m.setup = function()
  local group = vim.api.nvim_create_augroup('SelfGitsign', { clear = true })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufLeave' }, {
    group = group,
    callback = function(args)
      clearPreview(args.buf)
    end
  })
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = group,
    callback = function(args)
      invalidateOriginBuf(args.buf)
    end
  })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if (isInsideGitWorkTree(buf) == false or vim.o.filetype == 'netrw') then
        clearPreview(buf)
        invalidateOriginBuf(buf)
        return
      end
      clearPreview(buf)
      local diff = getDiff()
      gitsign_data[buf] = {}
      for _, chunk in ipairs(diff) do
        local status = 'c'
        if (chunk[2] == 0) then
          status = 'a'
        elseif (chunk[3] == 0) then
          status = 'db'
        elseif (chunk[4] == 0) then
          status = 'dn'
        end
        if (status == 'dn') then
          local oldStatus = gitsign_data[buf][chunk[3]]
          gitsign_data[buf][chunk[3]] = oldStatus == 'c' and 'cd' or status
        elseif (status == 'db') then
          local oldStatus = gitsign_data[buf][chunk[1]]
          gitsign_data[buf][chunk[1]] = oldStatus == 'c' and 'cd' or status
        else
          for i = chunk[3], chunk[3] + chunk[4] - 1 do
            gitsign_data[buf][i] = status
          end
        end
      end
    end
  })

  vim.keymap.set('n', '<leader>uu', function()
    m.open_diff()
  end, { desc = 'Git diff current hunk preview' })
end

return m
