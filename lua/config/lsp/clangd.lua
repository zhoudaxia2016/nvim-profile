local myutil = require 'config.lsp.util'
local map = require 'util'.map

local function basename(name)
  return name:match('([^:]+)$') or name
end

local function findSymbol(symbols, name)
  for _, s in ipairs(symbols) do
    local short = basename(s.name)
    if short == name or short == '~' .. name then
      return s
    end
    if s.children then
      local found = findSymbol(s.children, name)
      if found then
        return found
      end
    end
  end
end

-- 在刚切换过去的文件里定位同名符号。用 documentSymbol 而不是文本搜索：它只包含
-- 真实的声明/定义，不会误命中调用点。代价是要等 clangd 把这个 TU 解析完。
local function locateSymbol(word, tries)
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = 'clangd' })
  if #clients == 0 then
    -- 刚 :edit 进来 client 可能还没附着；等它附着再问（附着时 didOpen 已经发过）
    if tries > 0 then
      vim.defer_fn(function()
        locateSymbol(word, tries - 1)
      end, 200)
    end
    return
  end
  clients[1]:request('textDocument/documentSymbol', {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
  }, function(err, symbols)
    if err or not symbols then
      return
    end
    local sym = findSymbol(symbols, word)
    if not sym then
      return vim.notify(('这个文件里没有找到 %s'):format(word))
    end
    local rng = sym.selectionRange or sym.range
    local line = rng.start.line + 1
    if line > vim.api.nvim_buf_line_count(bufnr) then
      return
    end
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    -- 用 search 落到标识符上，避免自己做 utf-8 / utf-16 的字节换算
    vim.fn.search('\\<' .. vim.fn.escape(word, '\\/') .. '\\>', 'c', line)
  end, bufnr)
end

-- clangd 私有扩展请求（LSP 标准里没有），在 .h 和 .cpp 之间互跳
local function switchSourceHeader(client, bufnr, locate)
  local method = 'textDocument/switchSourceHeader'
  if not client:supports_method(method) then
    return vim.notify('clangd 不支持 switchSourceHeader')
  end
  local word = locate and vim.fn.expand('<cword>') or nil
  client:request(method, vim.lsp.util.make_text_document_params(bufnr), function(err, result)
    if err then
      return vim.notify(tostring(err), vim.log.levels.ERROR)
    end
    if not result then
      return vim.notify('没有找到配对的源文件/头文件')
    end
    vim.cmd.edit(vim.uri_to_fname(result))
    if word and word ~= '' then
      locateSymbol(word, 10)
    end
  end, bufnr)
end

vim.lsp.config('clangd', {
  root_markers = { '.clangd' },
  -- 键位放在 on_attach 里就是懒加载：只有 clangd 真正附着到 C/C++ buffer 时才注册，
  -- 而且是 buffer 局部的，不占启动时间，也不影响别的文件类型。
  on_attach = myutil.on_attachWithCb(function(client, bufnr)
    map('n', '<c-d>d', vim.lsp.buf.declaration, { desc = 'Declaration (usually the header)' }, bufnr)
    -- clangd 的 implementation 是"谁实现了这个虚函数/接口"，不是"函数体在哪个文件"。
    -- 后者要用 definition（<c-d><c-j>），且前提是 clangd 知道那个 .cpp。
    map('n', '<c-d>i', vim.lsp.buf.implementation, { desc = 'Implementations (virtual/interface)' }, bufnr)
    -- 切到对侧文件并落到同名符号上，代替原来的"只切文件、光标停在顶部"
    map('n', '<c-d>s', function()
      switchSourceHeader(client, bufnr, true)
    end, { desc = 'Switch source/header and locate' }, bufnr)
    -- 命令保持和 nvim-lspconfig 一致的纯切换语义
    vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdSwitchSourceHeader', function()
      switchSourceHeader(client, bufnr, false)
    end, { desc = 'Switch between source/header' })
  end),
})
