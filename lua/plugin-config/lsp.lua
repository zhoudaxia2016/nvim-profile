local cmd = vim.cmd
local opt = vim.opt
local lspconfig = require"lspconfig"
local map = require"util".map
local trim = require"util".trim
local ts_utils = require('nvim-treesitter.ts_utils')

local function run()
  local pos = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, 'textDocument/inlayHint', {
    range = {
      start = pos.position,
      ['end'] = { line = pos.position.line, character = pos.position.character + 1 },
    },
    textDocument = { uri = pos.textDocument.uri }
  }, function(err, result, ctx, config)
    if (result ~= nil and #result > 0) then
      local label
      if (#result == 1) then
        label = result[1].label
      else
        local current = ts_utils.get_node_at_cursor()
        local node = current:parent()
        while (node and node:type() ~= 'arguments') do
          current = node
          node = node:parent()
        end
        if node ~= nil then
          local startLine, startCharacter = ts_utils.get_node_range(current)
          for _, v in ipairs(result) do
            if (v.kind == 2) then
              if v.position.character == startCharacter and v.position.line == startLine then
                label = v.label
                break
              end
            end
          end
        end
      end
      if label ~= nil then
        vim.lsp.util.open_floating_preview({label}, 'typescript', {border = 'rounded'})
      end
    end
  end)
end
map('n', '<c-d><c-k>', run, { silent = true }, 0)

local on_attach = function(client, bufnr)
  opt.omnifunc = 'v:lua.vim.lsp.omnifunc'
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

  if client.resolved_capabilities.document_highlight then
    bindCursorEvent('CursorHold', 'document_highlight')
  end
  if client.resolved_capabilities.signatureHelp then
    bindCursorEvent('CursorHoldI', 'signature_help')
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
  map('v', 'f', vim.lsp.buf.range_formatting)
end

local function on_attachWithCb(cb)
  return function(client, bufnr)
    on_attach(client, bufnr)
    cb(client, bufnr)
  end
end

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = 'rounded'
  }
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signatureHelp, {
    border = 'rounded'
  }
)

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
local typescriptCommands = {
  goToSourceDefinition = '_typescript.goToSourceDefinition'
}
lspconfig.tsserver.setup {
  on_attach = on_attachWithCb(function(client, bufnr)
    client.resolved_capabilities.document_formatting = false
    client.resolved_capabilities.document_range_formatting = false
    map('n', '<c-d><c-j>', function()
      local pos = vim.lsp.util.make_position_params()
      vim.lsp.buf.execute_command({
        command = typescriptCommands.goToSourceDefinition,
        arguments = {pos.textDocument.uri, pos.position}
      })
    end, {}, bufnr)
  end),
  init_options = {
    plugins = {{ location = getPath(os.getenv('NODE_PATH'))} },
    preferences = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
    }
  },
  cmd = vim.env.debug ~= nil
    and {
      'node', '--inspect', trim(vim.fn.system('which typescript-language-server')), '--stdio',
      '--tsserver-log-file', os.getenv('HOME')..'/tsserver.log', '--log-level', '4'
    }
    or { bin_name, '--stdio' },
  handlers = {
    ['workspace/executeCommand'] = function(err, result, ctx, config)
      local command = ctx.params.command
      if command == typescriptCommands.goToSourceDefinition then
        if result ~= nil and #result > 0 then
          vim.lsp.util.jump_to_location(result[1], 'utf-8')
        end
      end
    end
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

lspconfig.marksman.setup {
  on_attach = on_attach,
}
