local lspconfig = require"lspconfig"

local eslint = {
  lintCommand = "eslint_d --no-error-on-unmatched-pattern --quiet -f unix --stdin --stdin-filename ${INPUT}",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintIgnoreExitCode = true,
  formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
  formatStdin = true
}

lspconfig.tsserver.setup {
  init_options = {
    documentFormatting = false
  }
}

lspconfig.efm.setup {
  init_options = {
    documentFormatting = true
  },
  root_dir = function()
    return vim.fn.getcwd()
  end,
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

-- 安装最新ninja
-- 参考 https://jdhao.github.io/2021/08/12/nvim_sumneko_lua_conf/
local sumneko_binary_path = vim.fn.exepath('lua-language-server')
local sumneko_root_path = vim.fn.fnamemodify(sumneko_binary_path, ':h:h:h')

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

require'lspconfig'.sumneko_lua.setup {
    cmd = {sumneko_binary_path, "-E", sumneko_root_path .. "/main.lua"};
    settings = {
        Lua = {
        runtime = {
            -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
            version = 'LuaJIT',
            -- Setup your lua path
            path = runtime_path,
        },
        diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = {'vim', 'table'},
        },
        workspace = {
            -- Make the server aware of Neovim runtime files
            library = vim.api.nvim_get_runtime_file("", true),
        },
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
            enable = false,
        },
        },
    },
}
