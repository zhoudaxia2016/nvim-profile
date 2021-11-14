local cmd = vim.cmd
local opt = vim.opt
local lspconfig = require"lspconfig"

local eslint = {
  lintCommand = "eslint_d --no-error-on-unmatched-pattern --quiet -f unix --stdin --stdin-filename ${INPUT}",
  lintStdin = true,
  lintFormats = {"%f:%l:%c: %m"},
  lintIgnoreExitCode = true,
  formatCommand = "eslint_d --fix-to-stdout --stdin --stdin-filename=${INPUT}",
  formatStdin = true,
}

local bin_name = 'typescript-language-server'
local getPath = function (str)
  return str:match("(.*/)")
end
lspconfig.tsserver.setup {
    init_options = { plugins = {{ name = 'ts-plugin-test', location = getPath(os.getenv('NODE_PATH'))} }},
    cmd = { bin_name, '--stdio', '--tsserver-log-file', os.getenv('HOME')..'/tsserver.log', '--log-level', '3' },
    handlers = {
      ['textDocument/formatting'] = nil
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
-- The following example advertise capabilities to `clangd`.
require'lspconfig'.html.setup {
}

local function bindCursorEvent(event, handler)
  cmd('autocmd '.. event ..  ' <buffer> lua if(IsExistActiveLspClient()) then vim.lsp.buf.' .. handler .. '() end')
end

bindCursorEvent('CursorHold', 'document_highlight')
bindCursorEvent('CursorHoldI', 'signature_help')
bindCursorEvent('CursorMoved', 'clear_references')
bindCursorEvent('CursorMovedI', 'clear_references')

function IsExistActiveLspClient()
  return table.getn(vim.lsp.get_active_clients()) ~= 0
end

local function normalKeymap(lhs, rhs)
  vim.api.nvim_set_keymap('n', lhs, '<Cmd>lua vim.lsp.' .. rhs .. '()<cr>', {})
end

normalKeymap('<c-d><c-h>', 'buf.hover')
normalKeymap('<c-d><c-j>', 'buf.definition')
normalKeymap('<c-d><c-n>', 'diagnostic.goto_next')
normalKeymap('<c-d><c-p>', 'diagnostic.goto_prev')
normalKeymap('<c-d><c-m>', 'buf.rename')
normalKeymap('<c-d><c-l>', 'buf.references')
normalKeymap('<c-f>', 'buf.formatting_seq_sync')
normalKeymap('<c-d><c-o>', 'buf.code_action')

opt.omnifunc = 'v:lua.vim.lsp.omnifunc'
opt.updatetime = 500

cmd [[hi LspReferenceText guibg=#6b778d]]
cmd [[hi LspReferenceRead guibg=#6b778d]]
cmd [[hi LspReferenceWrite guibg=#6b778d]]
cmd [[hi LspSignatureActiveParameter guibg=#6b778d]]

local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end
