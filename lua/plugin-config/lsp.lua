local cmd = vim.cmd
local opt = vim.opt
local lspconfig = require"lspconfig"
local myutil = require"plugin-config.lsp.util"

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = 'rounded'
  }
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help, {
    border = 'rounded',
    silent = true,
    focusable = false,
  }
)

vim.api.nvim_create_autocmd('User', {
  pattern = 'LspProgressUpdate',
  callback = function()
    local msgs = vim.lsp.util.get_progress_messages()
    for _, msg in ipairs(msgs) do
      vim.notify(msg.name .. ': ' .. msg.title)
    end
  end
})

opt.updatetime = 500
vim.o.completeopt = 'menu'

cmd [[hi LspReferenceText guibg=#6b778d]]
cmd [[hi LspReferenceRead guibg=#6b778d]]
cmd [[hi LspReferenceWrite guibg=#6b778d]]
cmd [[hi LspSignatureActiveParameter guibg=#6b778d]]

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

lspconfig.marksman.setup {
  on_attach = myutil.on_attach,
}
lspconfig.ccls.setup {
  on_attach = myutil.on_attach,
}
lspconfig.flow.setup {
  on_attach = myutil.on_attach,
}

require('plugin-config.lsp.tsserver')
require('plugin-config.lsp.efm')
require('plugin-config.lsp.sumneko')
