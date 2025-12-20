local util = require"lspconfig.util"
local map = require"util".map
local myutil = require"base-config.lsp.util"
local trim = require"util".trim
local _util = require('base-config.lsp._util')

local bin_name = 'typescript-language-server'
local getPath = function (str)
  return str:match("(.*/)")
end
local typescriptCommands = {
  goToSourceDefinition = '_typescript.goToSourceDefinition',
  renameFile = '_typescript.applyRenameFile',
}

local settings = {
  format = {
    insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = false,
  },
}

local supportGotoSource = false

vim.lsp.handlers['$/typescriptVersion'] = function(_, result, _, _)
  supportGotoSource = vim.version.ge(result.version, '4.7')
end

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
        local current = vim.treesitter.get_node()
        local node = current:parent()
        while (node and node:type() ~= 'arguments') do
          current = node
          node = node:parent()
        end
        if node ~= nil then
          local startLine, startCharacter = vim.treesitter.get_node_range(current)
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

local function renameFile(sourceUri, newName)
  local targetUri = sourceUri:gsub('([^/]+)$', newName)
  local sourceName = vim.uri_to_fname(sourceUri)
  local targetName = vim.uri_to_fname(targetUri)
  vim.lsp.buf.execute_command({
    command = typescriptCommands.renameFile,
    arguments = {{sourceUri = sourceUri, targetUri = targetUri}}
  })
  vim.lsp.util.rename(sourceName, targetName, {})
end


vim.lsp.config('ts_ls', {
  on_attach = myutil.on_attachWithCb(function(client, bufnr)
    client.server_capabilities.document_formatting = false
    client.server_capabilities.document_range_formatting = false
    map('n', '<c-d><c-k>', showInlayHint, { silent = true }, 0)
    map('n', '<c-d><c-j>', function()
      if supportGotoSource == false then
        vim.lsp.buf.definition()
        return
      end
      local pos = vim.lsp.util.make_position_params()
      vim.lsp.buf.execute_command({
        command = typescriptCommands.goToSourceDefinition,
        arguments = {pos.textDocument.uri, pos.position}
      })
    end, {}, bufnr)
    map('n', '<C-LeftMouse>', function()
      vim.schedule(function()
        if supportGotoSource == false then
          vim.lsp.buf.definition()
          return
        end
        local pos = _util.make_mouse_postion_param()
        vim.lsp.buf.execute_command({
          command = typescriptCommands.goToSourceDefinition,
          arguments = {vim.lsp.util.make_text_document_params().uri, pos}
        })
      end)
      return '<C-LeftMouse>'
    end, {expr = true}, bufnr)
    vim.api.nvim_create_user_command('RenameDir',
      function(opts)
        local sourceUri = vim.fs.dirname(vim.uri_from_bufnr(0))
        renameFile(sourceUri, opts.fargs[1])
      end,
      {
        nargs = 1,
      }
    )
    vim.api.nvim_create_user_command('RenameFile',
      function(opts)
        local sourceUri = vim.uri_from_bufnr(0)
        local alternateFile = vim.fn.getreg('#')
        renameFile(sourceUri, opts.fargs[1])
        vim.fn.setreg('#', alternateFile)
      end,
      {
        nargs = 1,
      }
    )
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
      insertSpaceAfterOpeningAndBeforeClosingNonemptyBrackets = false,
    },
    tsserver = {
      logDirectory = '/tmp',
      logVerbosity = vim.env.debug ~= nil and 'verbose' or 'off'
    }
  },
  settings = {
    javascript = settings,
    typescript = settings,
    javascriptreact = settings,
    typescriptreact = settings,
    ["javascript.jsx"] = settings,
    ["typescript.tsx"] = settings,
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
          vim.lsp.util.show_document(result[1], 'utf-8', {reuse_win = true, focus = true})
        end
      end
    end
  },
  capabilities = {
    textDocument = {
      codeLens = {}
    }
  },
})
