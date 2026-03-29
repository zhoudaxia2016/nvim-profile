local M = {}

local function get_project_root()
  return vim.fs.root(vim.fn.getcwd(), {'.git', 'package.json'})
end

local function find_pane()
  local root = get_project_root()
  if not root then return end
  local output = vim.fn.systemlist(
    "tmux list-panes -a -F '#{pane_id}|#{window_id}|#{pane_current_path}|#{pane_current_command}'"
  )
  for _, line in ipairs(output) do
    local p_id, w_id, path, cmd = line:match("^(%%%d+)|(@%d+)|(.+)|(.+)$")
    if path == root and cmd:lower():find("opencode") then
      return p_id, w_id
    end
  end
end

local function send(msg)
  local pane, win = find_pane()
  if not pane then return end
  vim.fn.system({ "tmux", "send-keys", "-t", pane, msg })
  if win then
    vim.fn.system({ "tmux", "select-window", "-t", win })
  end
end

_G._opencode_err_op = function()
  local root = get_project_root()
  if not root then return end
  local full_path = vim.fn.expand("%:p")
  local file = full_path:sub(#root + 2)
  local bufnr = vim.api.nvim_get_current_buf()

  local s, e = vim.fn.line("'["), vim.fn.line("']")
  local err_parts = {}

  local lsp_errs = vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR })
  for _, err in ipairs(lsp_errs) do
    if err.lnum + 1 >= s and err.lnum + 1 <= e then
      table.insert(err_parts, string.format("%s:%d:%d: %s", file, err.lnum + 1, err.col + 1, err.message))
    end
  end

  -- 如果没有lsp错误，则发送nvim运行错误
  if #err_parts == 0 then
    local last_err = vim.v.errmsg
    if last_err and last_err ~= "" then
      -- TODO: 优化nvim错误信息
      table.insert(err_parts, string.format("[nvim error]: %s", last_err))
    end
  end

  if #err_parts == 0 then return end
  local err_msg = table.concat(err_parts, " | ")
  send(err_msg)
end

_G._opencode_op = function()
  local root = get_project_root()
  if not root then return end
  local full_path = vim.fn.expand("%:p")
  local file = full_path:sub(#root + 2)
  local s, e = vim.fn.line("'["), vim.fn.line("']")
  local ref = string.format("@%s (lines %d-%d): ", file, s, e)
  send(ref)
end

vim.keymap.set({'n', 'v'}, "<leader>oa", function()
  vim.o.operatorfunc = "v:lua._opencode_op"
  return "g@"
end, { expr = true, silent = true, noremap = true, desc = "Send @file ref to opencode" })

vim.keymap.set({'n', 'v'}, "<leader>oe", function()
  vim.o.operatorfunc = "v:lua._opencode_err_op"
  return "g@"
end, { expr = true, silent = true, noremap = true, desc = "Send errors to opencode" })

return M