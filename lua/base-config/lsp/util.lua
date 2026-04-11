local map = require"util".map
local debounce = require'util.debounce'
local api = vim.api
local goto_doc_hl_result = require('base-config.lsp.featrues.document_highlight').goto_doc_hl_result

M = {}

local make_floating_popup_options = vim.lsp.util.make_floating_popup_options
vim.lsp.util.make_floating_popup_options = function(...)
  local opts = make_floating_popup_options(...)
  local lines_above = vim.fn.screenpos(0, vim.fn.line('.'), 1).row
  local lines_below = vim.o.lines - lines_above
  local above = lines_above > lines_below
  local anchor = above and 'S' or 'N'
  opts.row = above and 0 or 1
  opts.anchor = anchor .. opts.anchor:sub(2, 2)
  return opts
end

--- @param client vim.lsp.Client
--- @param bufnr integer
local on_attach = function(client, bufnr)
  local capabilities = client.server_capabilities or {}
  vim.lsp.completion.enable(true, client.id, bufnr, {autotrigger = false})
  if vim.o.diff then
    vim.diagnostic.enable(false)
  end
  local function bindCursorEvent(event, handler)
    vim.api.nvim_create_autocmd(event, {
      callback = function()
        vim.lsp.buf[handler]()
      end,
      buffer = bufnr,
    })
  end

  if capabilities.documentHighlightProvider then
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

  nmap('<c-d><c-h>', function()
    vim.lsp.buf.hover({border = 'rounded'})
  end)
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
    vim.diagnostic.jump(vim.tbl_extend('force', diagnosticConfig, {count = 1}))
  end, true)
  nmap('<c-d><c-p>', function()
    vim.diagnostic.jump(vim.tbl_extend('force', diagnosticConfig, {count = -1}))
  end, true)
  map('v', 'f', 'format')
  nmap('gyi', function()
    goto_doc_hl_result(1)
  end)
  nmap('gyI', function()
    goto_doc_hl_result(-1)
  end)

  if (client.server_capabilities.signatureHelpProvider) then
    vim.api.nvim_create_autocmd('CursorMovedI', {
      buffer = bufnr,
      callback = debounce(function()
        vim.lsp.buf.signature_help({
          border = 'rounded',
          silent = true,
          focusable = false,
          max_height = math.ceil(vim.o.lines / 2) - 2,
        })
      end, 300)
    })
  end

  -- if capabilities.inlayHintProvider then
  --   vim.lsp.buf.inlay_hint(bufnr, true)
  -- end
  vim.lsp.document_color.enable(true, { bufnr = bufnr }, { style = 'virtual' })
end

M.on_attach = on_attach

function M.on_attachWithCb(cb)
  return function(client, bufnr)
    on_attach(client, bufnr)
    cb(client, bufnr)
  end
end
return M
