local M = {}

local function get_project_root()
  return vim.fs.root(vim.fn.getcwd(), {'.git', 'package.json'})
end

function M.send_ref()
  local root = get_project_root()
  if not root then return end

  local pane, win
  local output = vim.fn.systemlist(
    "tmux list-panes -a -F '#{pane_id}|#{window_id}|#{pane_current_path}|#{pane_current_command}'"
  )

  for _, line in ipairs(output) do
    local p_id, w_id, path, cmd = line:match("^(%%%d+)|(@%d+)|(.+)|(.+)$")
    if path == root and cmd:lower():find("opencode") then
      pane, win = p_id, w_id
      break
    end
  end

  if not pane then return end

  local full_path = vim.fn.expand("%:p")
  local file = full_path:sub(#root + 2)
  local s, e = vim.fn.line("'["), vim.fn.line("']")
  local ref = string.format("@%s (lines %d-%d): ", file, s, e)
  vim.fn.system({ "tmux", "send-keys", "-t", pane, ref })
  if win then
    vim.fn.system({ "tmux", "select-window", "-t", win })
  end
end

_G._opencode_op = function()
  M.send_ref()
end

vim.keymap.set({'n', 'v'}, "<leader>oa", function()
  vim.o.operatorfunc = "v:lua._opencode_op"
  return "g@"
end, { expr = true, silent = true, noremap = true, desc = "Send @file ref to opencode" })

return M