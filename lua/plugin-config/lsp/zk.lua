local lspconfig = require"lspconfig"
local fzf = require"self-plugin.fzf".run
local previewer = require('self-plugin.fzf.previewer')

local tags = {}
local function getTags(cb)
  vim.lsp.buf_request(0, 'workspace/executeCommand', {
    command = 'zk.tag.list',
    arguments = {
      vim.api.nvim_buf_get_name(0),
    },
  }, function(_, result)
      tags = result
      if cb then
        cb(result)
      end
  end)
end

local function new(...)
  local opts = vim.api.nvim_eval(...)
  vim.lsp.buf_request(0, 'workspace/executeCommand', {
    command = 'zk.new',
    arguments = {vim.api.nvim_buf_get_name(0), opts}
  }, function(_, result, _, _)
      if not (result and result.path) then
        return
      end
      vim.cmd('tab drop ' .. result.path)
  end)
end

local function list(opts, onFailed)
  opts = vim.tbl_extend('force', {select = {'title', 'path', 'absPath'}}, opts)
  vim.lsp.buf_request(0, 'workspace/executeCommand', {
    command = 'zk.list',
    arguments = {
      vim.api.nvim_buf_get_name(0),
      opts,
    },
  }, function(_, result, _, _)
      if #result == 0 then
        if onFailed then
          onFailed()
        end
        return
      end
      if #result == 1 then
        vim.cmd('tab drop ' .. result[1].absPath)
        return
      end
      for _, item in pairs(result) do
        item.text = ('%s %s'):format(item.path, item.title)
      end
      fzf({
        input = result,
        multi = true,
        preparePreview = function(args)
          return {fn = args.absPath}
        end,
        acceptCb = function(args)
          for _, f in pairs(args) do
            vim.cmd('tab drop ' .. f.absPath)
          end
        end,
      })
    end)
end

-- 部分命令依赖zk alias配置
-- reference https://github.com/zhoudaxia2016/note/blob/main/.zk/config.toml
lspconfig.zk.setup {
  commands = {
    ZKNew = {
      new,
      nargs = '?',
    },
    ZKDaily = {
      function() new({dir = 'daily'}) end,
    },
    ZKTags = {
      function()
        getTags(function(result)
          fzf({
            hidePreview = true,
            multi = true,
            input = vim.tbl_map(function(item) return {text = item.name} end, result),
            acceptCb = function(args)
              args = vim.tbl_map(function(item) return item.text end, args)
              vim.cmd('ZkListTags ' .. vim.fn.join(args, ' '))
            end,
          })
        end)
      end,
    },
    ZKListMatch = {
      function(...)
        local keys = {...}
        list({match = keys}, function()
          vim.notify('No match notes for: ' .. vim.fn.join(keys, ' '))
        end)
      end,
      nargs = '+',
    },
    ZkListTags = {
      function(...)
        local searchTags = {...}
        list({tags = searchTags}, function()
          vim.notify('No result for tags: ' .. vim.fn.join(searchTags, ' '))
        end)
      end,
      nargs = '+',
      complete = function(lead)
        getTags()
        return vim.tbl_filter(function(item)
          return item:match('^' .. lead)
        end, vim.tbl_map(function(item) return item.name end, tags))
      end,
    }
  }
}
