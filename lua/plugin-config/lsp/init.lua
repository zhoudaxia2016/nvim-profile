local cmd = vim.cmd
local opt = vim.opt
local lspconfig = require"lspconfig"
local myutil = require"plugin-config.lsp.util"
local icons = require"util.icons"

local msgFilter = {'tsserver'}

vim.api.nvim_create_autocmd('LspProgress', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and vim.tbl_contains(msgFilter, client.name, {}) then
      local value = args.data.params.value
      vim.notify(string.format('[%s] %s', value.kind == 'begin' and '...' or 'Done', value.title))
    end
  end
})

opt.updatetime = 500
vim.o.completeopt = 'menu,fuzzy,popup'

cmd [[hi LspReferenceText guibg=#6b778d]]
cmd [[hi LspReferenceRead guibg=#6b778d]]
cmd [[hi LspReferenceWrite guibg=#6b778d]]
cmd [[hi LspSignatureActiveParameter guibg=#6b778d]]


for _, type in pairs(vim.diagnostic.severity) do
  local hl = "DiagnosticSign" .. type
end
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.cross .. " ",
      [vim.diagnostic.severity.WARN] = icons.exclamation_reverse .. " ",
      [vim.diagnostic.severity.HINT] = icons.bulb .. " ",
      [vim.diagnostic.severity.INFO] = icons.info .. " ",
    }
  },
})
vim.diagnostic.enable()

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
lspconfig.gopls.setup {
  on_attach = myutil.on_attach,
}

require('plugin-config.lsp.tsserver')
require('plugin-config.lsp.efm')
require('plugin-config.lsp.sumneko')
require('plugin-config.lsp.zk')

-- TODO: 待完善
-- 现在的实现edit的执行可能有冲突，不能完全fix all
vim.api.nvim_create_user_command('FixAll', function()
  vim.diagnostic.setloclist()
  vim.cmd("ldo lua vim.lsp.buf.code_action({apply=true, context={only={'quickfix'}}, filter = function(_) return string.find(_.title, 'Declare property') end})")
end, {})
