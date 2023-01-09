local map = require"util".map

M = {}
local on_attach = function(client, bufnr)
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
  nmap('<c-d><c-o>', 'code_action')
  nmap('<c-d><c-y>', 'type_definition')
  local diagnosticConfig = { severity = vim.diagnostic.severity.ERROR, float = { border = "rounded" }}
  nmap('<c-d><c-n>', function()
    vim.diagnostic.goto_next(diagnosticConfig)
  end, true)
  nmap('<c-d><c-p>', function()
    vim.diagnostic.goto_prev(diagnosticConfig)
  end, true)
  map('v', 'f', 'format')
end

M.on_attach = on_attach

function M.on_attachWithCb(cb)
  return function(client, bufnr)
    on_attach(client, bufnr)
    cb(client, bufnr)
  end
end
return M
