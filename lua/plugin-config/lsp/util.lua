local map = require"util".map
local debounce = require'util.debounce'
local api = vim.api
local fzf = require('self-plugin.fzf')

M = {}

vim.lsp.handlers['textDocument/references'] = function(_, result, ctx, config)
  if not result or vim.tbl_isempty(result) then
    vim.notify('No references found')
    return
  end
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  config = config or {}
  local items = vim.lsp.util.locations_to_items(result, client.offset_encoding)
  items = vim.tbl_map(function(item)
    return string.format('%s:%s | %s %s', item.lnum, item.col, item.text, item.filename)
  end, items)
  fzf.run({
    cmd = 'fzf --with-nth ..-2',
    input = items,
    previewCb = function(_, index, ns)
      local item = result[index]
      local startRange = item.range.start
      local endRange = item.range['end']
      local fn = vim.uri_to_fname(item.uri)
      vim.cmd(string.format('edit +%s %s', startRange.line + 1, fn))
      vim.highlight.range(0, ns, 'Todo', {startRange.line, startRange.character}, {endRange.line, endRange.character}, {priority = 9999})
    end,
    acceptCb = function(args)
      local line = string.match(args, '^%d+')
      local fn = string.match(args, '%S+$')
      vim.cmd(string.format('tabnew +%s %s', line, fn))
    end,
  })
end

local on_attach = function(client, bufnr)
  local capabilities = client.server_capabilities
  -- TODO: remove that after #21001 fixed
  if capabilities.completionProvider then
    vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
  end
  if vim.o.diff then
    vim.diagnostic.disable()
  end
  local function bindCursorEvent(event, handler)
    vim.api.nvim_create_autocmd(event, {
      callback = function()
        vim.lsp.buf[handler]()
      end,
      buffer = bufnr,
    })
  end

  if client.server_capabilities.document_highlight then
    bindCursorEvent('CursorHold', 'document_highlight')
  end
  bindCursorEvent('CursorMoved', 'clear_references')
  bindCursorEvent('CursorMovedI', 'clear_references')

  local function nmap(lhs, rhs, noprefix)
    local fn = rhs
    if type(rhs) == 'string' then
      fn = function()
        vim.lsp.buf[rhs]()
      end
    end
    map('n', lhs, fn, { silent = true }, bufnr)
  end

  nmap('<c-d><c-h>', 'hover')
  nmap('<c-d><c-j>', 'definition')
  nmap('<c-d><c-u>', 'rename')
  nmap('<c-d><c-l>', 'references')
  nmap('<c-d>f', 'formatting_seq_sync')
  nmap('<c-d><c-o>', function()
    -- TODO: wait for be fixed by up stream
    local function get_diagnostic_at_cursor()
      local cur_buf = api.nvim_get_current_buf()
      local line, col = unpack(api.nvim_win_get_cursor(0))
      local entrys = vim.diagnostic.get(cur_buf, { lnum = line - 1 })
      local res = {}
      for _, v in pairs(entrys) do
        if v.col <= col and v.end_col >= col then
          table.insert(res, {
            code = v.code,
            message = v.message,
            range = {
              ['start'] = {
                character = v.col,
                line = v.lnum,
              },
              ['end'] = {
                character = v.end_col,
                line = v.end_lnum,
              },
            },
            severity = v.severity,
            source = v.source or nil,
          })
        end
      end
      return res
    end

    vim.lsp.buf.code_action({
      context = {
        diagnostics = get_diagnostic_at_cursor()
      }
    })
  end)
  nmap('<c-d><c-y>', 'type_definition')
  nmap('<c-d><c-d>', function()
    vim.diagnostic.open_float({border = 'rounded'})
  end)
  local diagnosticConfig = { severity = vim.diagnostic.severity.ERROR, float = { border = "rounded" }}
  nmap('<c-d><c-n>', function()
    vim.diagnostic.goto_next(diagnosticConfig)
  end, true)
  nmap('<c-d><c-p>', function()
    vim.diagnostic.goto_prev(diagnosticConfig)
  end, true)
  map('v', 'f', 'format')

  if (client.server_capabilities.signatureHelpProvider) then
    local function bindEvent()
      local id = vim.api.nvim_create_augroup("MyGroup", {
        clear = true
      })
      vim.api.nvim_create_autocmd('CursorMovedI', {
        group = id,
        callback = debounce(function()
          vim.lsp.buf.signature_help()
        end, 300)
      })
    end
    bindEvent()
    vim.api.nvim_create_autocmd('InsertLeave', {
      callback = bindEvent
    })
  end
end

M.on_attach = on_attach

function M.on_attachWithCb(cb)
  return function(client, bufnr)
    on_attach(client, bufnr)
    cb(client, bufnr)
  end
end
return M
