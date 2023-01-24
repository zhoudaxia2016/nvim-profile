local myutil = require"plugin-config.lsp.util"
local lspconfig = require"lspconfig"
local util = require 'lspconfig.util'

local eslint = {
  lintCommand = "eslint_d --no-error-on-unmatched-pattern --quiet -f unix --stdin --stdin-filename ${INPUT}",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintIgnoreExitCode = true,
  formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
  formatStdin = true,
}

lspconfig.efm.setup {
  on_attach = myutil.on_attach,
  init_options = {
    documentFormatting = true,
    codeAction = true,
  },
  root_dir = util.root_pattern('.eslintrc.*', '.git'),
  settings = {
    languages = {
      javascript = {eslint},
      javascriptreact = {eslint},
      ["javascript.jsx"] = {eslint},
      typescript = {eslint},
      ["typescript.tsx"] = {eslint},
      typescriptreact = {eslint}
    }
  },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescript.tsx",
    "typescriptreact"
  },
}
