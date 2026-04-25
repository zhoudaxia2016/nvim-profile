local M = {}
local TARGETS = {
  codex = { "codex" },
  opencode = { "opencode" },
}
local pane_cache = {}

local function get_project_root()
  return vim.fs.root(vim.fn.getcwd(), {'.git', 'package.json'})
end

local function match_backend_in_text(text)
  if not text or text == "" then
    return nil
  end

  local lower_text = text:lower()
  for backend, patterns in pairs(TARGETS) do
    for _, pattern in ipairs(patterns) do
      if lower_text:find(pattern, 1, true) then
        return backend
      end
    end
  end
  return nil
end

local function detect_backend(pane_pid, current_cmd, start_cmd, title)
  local backend = match_backend_in_text(current_cmd)
    or match_backend_in_text(start_cmd)
    or match_backend_in_text(title)
  if backend then
    return backend
  end

  if not current_cmd or current_cmd:lower() ~= "node" then
    return nil
  end

  local children = vim.fn.systemlist({ "ps", "--ppid", pane_pid, "-o", "args=" })
  for _, child in ipairs(children) do
    backend = match_backend_in_text(child)
    if backend then return backend end
  end

  return nil
end

local function pane_exists(pane_id)
  local result = vim.fn.systemlist({ "tmux", "list-panes", "-t", pane_id, "-F", "#{pane_id}" })
  return vim.v.shell_error == 0 and result[1] == pane_id
end

local function get_cached_pane(root)
  local cached = pane_cache[root]
  if not cached then
    return nil
  end

  if not pane_exists(cached.pane_id) then
    pane_cache[root] = nil
    return nil
  end

  return cached
end

local function cache_pane(root, pane_id, window_id, backend)
  pane_cache[root] = {
    pane_id = pane_id,
    window_id = window_id,
    backend = backend,
  }
end

local function find_pane()
  local root = get_project_root()
  if not root then return end

  local cached = get_cached_pane(root)
  if cached then
    return cached
  end

  local pane_format = table.concat({
    "#{pane_id}",
    "#{window_id}",
    "#{pane_pid}",
    "#{pane_current_path}",
    "#{pane_current_command}",
    "#{pane_start_command}",
    "#{pane_title}",
  }, "|")
  local output = vim.fn.systemlist(string.format("tmux list-panes -a -F '%s'", pane_format))
  for _, line in ipairs(output) do
    local p_id, w_id, pane_pid, path, current_cmd, start_cmd, title =
      line:match("^(%%%d+)|(@%d+)|(%d+)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
    if path == root then
      local backend = detect_backend(pane_pid, current_cmd, start_cmd, title)
      if backend then
        cache_pane(root, p_id, w_id, backend)
        return pane_cache[root]
      end
    end
  end
end

local function send(msg, target)
  target = target or find_pane()
  if not target then return end
  vim.fn.system({ "tmux", "send-keys", "-t", target.pane_id, msg, "C-m" })
  if target.window_id then
    vim.fn.system({ "tmux", "select-window", "-t", target.window_id })
  end
end

local function build_ref(backend, file, s, e)
  if backend == "codex" then
    return string.format("Check file `%s` lines %d-%d.", file, s, e)
  end

  return string.format("@%s (lines %d-%d): ", file, s, e)
end

local function build_error(backend, err_msg)
  if backend == "codex" then
    return string.format("These are the current errors for the selected code:\n%s", err_msg)
  end

  return err_msg
end

function M.clear_cache()
  local root = get_project_root()
  if root then
    pane_cache[root] = nil
  else
    pane_cache = {}
  end
end

_G._opencode_err_op = function()
  local root = get_project_root()
  if not root then return end
  local target = find_pane()
  if not target then return end
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
  send(build_error(target.backend, err_msg), target)
end

_G._opencode_op = function()
  local root = get_project_root()
  if not root then return end
  local target = find_pane()
  if not target then return end
  local full_path = vim.fn.expand("%:p")
  local file = full_path:sub(#root + 2)
  local s, e = vim.fn.line("'["), vim.fn.line("']")
  local ref = build_ref(target.backend, file, s, e)
  send(ref, target)
end

vim.keymap.set({'n', 'v'}, "<leader>oa", function()
  vim.o.operatorfunc = "v:lua._opencode_op"
  return "g@"
end, { expr = true, silent = true, noremap = true, desc = "Send selection to agent" })

vim.keymap.set({'n', 'v'}, "<leader>oe", function()
  vim.o.operatorfunc = "v:lua._opencode_err_op"
  return "g@"
end, { expr = true, silent = true, noremap = true, desc = "Send errors to agent" })

vim.api.nvim_create_user_command("AgentPaneClearCache", function()
  M.clear_cache()
end, { desc = "Clear cached agent pane for current project" })

return M
