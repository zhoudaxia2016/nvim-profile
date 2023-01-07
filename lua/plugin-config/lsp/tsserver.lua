local lspconfig = require"lspconfig"
local util = require"lspconfig.util"
local ts_utils = require('nvim-treesitter.ts_utils')
local map = require"util".map
local myutil = require"plugin-config.lsp.util"
local trim = require"util".trim

local bin_name = 'typescript-language-server'
local getPath = function (str)
  return str:match("(.*/)")
end
local typescriptCommands = {
  goToSourceDefinition = '_typescript.goToSourceDefinition'
}

local function showInlayHint()
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


lspconfig.tsserver.setup {
  root_dir = function(fname)
    if (util.root_pattern('.flowconfig')(fname)) then
      return nil
    end
    return util.root_pattern 'tsconfig.json'(fname)
    or util.root_pattern('package.json', 'jsconfig.json', '.git')(fname)
  end,
  on_attach = myutil.on_attachWithCb(function(client, bufnr)
    client.server_capabilities.document_formatting = false
    client.server_capabilities.document_range_formatting = false
    map('n', '<c-d><c-k>', showInlayHint, { silent = true }, 0)
    map('n', '<c-d><c-j>', function()
      local pos = vim.lsp.util.make_position_params()
      vim.lsp.buf.execute_command({
        command = typescriptCommands.goToSourceDefinition,
        arguments = {pos.textDocument.uri, pos.position}
      })
    end, {}, bufnr)
  end),
  init_options = {
    plugins = vim.env.tsserverPlugins
      and vim.tbl_map(function(_)
          return { location = getPath(os.getenv('NODE_PATH')), name = _}
        end, vim.split(vim.env.tsserverPlugins, ' '))
      or {},
    maxTsServerMemory = 999999,
    preferences = {
          includeInlayEnumMemberValueHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayVariableTypeHints = true,
    },
    tsserver = {
      logDirectory = '/tmp',
      logVerbosity = vim.env.debug ~= nil and 'verbose' or 'off'
    }
  },
  cmd = vim.env.debug ~= nil
    and {
      'node', '--inspect-brk', trim(vim.fn.system('which typescript-language-server')), '--stdio'
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
