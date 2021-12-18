local cmd = vim.cmd
local opt = vim.opt
local lspconfig = require"lspconfig"

local on_attach = function(client, bufnr)
  if vim.o.diff then
    vim.diagnostic.disable()
  end
  local function bindCursorEvent(event, handler)
    cmd('autocmd '.. event ..  ' <buffer> lua vim.lsp.buf.' .. handler .. '()')
  end

  if client.resolved_capabilities.document_highlight then
    bindCursorEvent('CursorHold', 'document_highlight')
  end
  if client.resolved_capabilities.signatureHelp then
    bindCursorEvent('CursorHoldI', 'signature_help')
  end
  bindCursorEvent('CursorMoved', 'clear_references')
  bindCursorEvent('CursorMovedI', 'clear_references')

  local function normalKeymap(lhs, rhs)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', lhs, '<Cmd>lua vim.lsp.' .. rhs .. '()<cr>', { silent = true })
  end

  normalKeymap('<c-d><c-h>', 'buf.hover')
  normalKeymap('<c-d><c-j>', 'buf.definition')
  normalKeymap('<c-d><c-n>', 'diagnostic.goto_next')
  normalKeymap('<c-d><c-p>', 'diagnostic.goto_prev')
  normalKeymap('<c-d><c-m>', 'buf.rename')
  normalKeymap('<c-d><c-l>', 'buf.references')
  normalKeymap('<c-d>f', 'buf.formatting_seq_sync')
  normalKeymap('<c-d><c-o>', 'buf.code_action')
  normalKeymap('<c-d><c-y>', 'buf.type_definition')
  normalKeymap('<c-d><c-u>', 'lua print("diagnostic count: table.getn(vim.diagnostic.get())"')
  vim.api.nvim_set_keymap('n', '<c-d><c-u>', '<Cmd>lua print("diagnostic count: " .. table.getn(vim.diagnostic.get()))<cr>', { silent = true })
end

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
  on_attach = on_attach,
  init_options = { plugins = {{ name = 'ts-plugin-test', location = getPath(os.getenv('NODE_PATH'))} }},
  cmd = { bin_name, '--stdio', '--tsserver-log-file', os.getenv('HOME')..'/tsserver.log', '--log-level', '3' },
  handlers = {
    ['textDocument/formatting'] = nil
  }
}

lspconfig.efm.setup {
  on_attach = on_attach,
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
  on_attach = on_attach,
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



opt.omnifunc = 'v:lua.vim.lsp.omnifunc'
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

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
lspconfig.jsonls.setup{
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    json = {
      schemas = {
        {
          fileMatch = { "tsconfig.json", "tsconfig.*.json" },
          url = "http://json.schemastore.org/tsconfig"
        }
      }
    }
  }
}

