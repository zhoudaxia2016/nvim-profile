local cmd = vim.cmd
local opt = vim.opt
local lspconfig = require"lspconfig"
local myutil = require"plugin-config.lsp.util"

local msgFilter = {'tsserver'}

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
    max_height = math.ceil(vim.o.lines / 2) - 2,
  }
)

vim.api.nvim_create_autocmd('LspProgress', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and vim.tbl_contains(msgFilter, client.name, {}) then
      local value = args.data.result.value
      vim.notify(string.format('[%s] %s', value.kind == 'begin' and '...' or 'Done', value.title))
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
lspconfig.clangd.setup {
  on_attach = myutil.on_attach,
}
lspconfig.flow.setup {
  on_attach = myutil.on_attach,
}
lspconfig.rust_analyzer.setup({
    on_attach= myutil.on_attach,
    settings = {
        ["rust-analyzer"] = {
            imports = {
                granularity = {
                    group = "module",
                },
                prefix = "self",
            },
            cargo = {
                buildScripts = {
                    enable = true,
                },
            },
            procMacro = {
                enable = true
            },
        }
    }
})

require('plugin-config.lsp.tsserver')
require('plugin-config.lsp.efm')
require('plugin-config.lsp.sumneko')
