local map = require"util".map
local debounce = require'util.debounce'
local api = vim.api
local fzf = require('self-plugin.fzf')
local _util = require('plugin-config.lsp._util')

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

vim.lsp.handlers['textDocument/references'] = function(_, result, _, _)
  if not result or vim.tbl_isempty(result) then
    vim.notify('No references found')
    return
  end
  for _, item in pairs(result) do
    local start = item.range.start
    item.text = _util.get_line(vim.uri_to_bufnr(item.uri), start.line)
    item.filename = vim.uri_to_fname(item.uri)
  end
  fzf.run({
    input = result,
    multi = true,
    transform = function(item)
      local start = item.range.start
      return string.format('%s:%s | %s', start.line + 1, start.character + 1, item.text)
    end,
    getPreviewTitle = function(args)
      return args.filename
    end,
    previewCb = function(args, ns)
      local startRange = args.range.start
      local endRange = args.range['end']
      local fn = args.filename
      vim.cmd(string.format('edit +%s %s', startRange.line + 1, fn))
      vim.highlight.range(0, ns, 'Todo', {startRange.line, startRange.character}, {endRange.line, endRange.character}, {priority = 9999})
    end,
    acceptCb = function(args)
      for _, f in ipairs(args) do
        local start = f.range.start
        local line = start.line + 1
        local col = start.character
        local fn = f.filename
        vim.cmd(string.format('tab drop +%s %s | normal %sl', line, fn, col))
      end
    end,
  })
end

local on_attach = function(client, bufnr)
  local capabilities = client.server_capabilities
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
    vim.diagnostic.goto_next(diagnosticConfig)
  end, true)
  nmap('<c-d><c-p>', function()
    vim.diagnostic.goto_prev(diagnosticConfig)
  end, true)
  map('v', 'f', 'format')

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
end

M.on_attach = on_attach

function M.on_attachWithCb(cb)
  return function(client, bufnr)
    on_attach(client, bufnr)
    cb(client, bufnr)
  end
end
return M
