local M = {}

local function execute(cmd, cwd)
  local result = vim.system(cmd, { text = true, cwd = cwd }):wait()
  return result.code, result.stdout or '', result.stderr or ''
end

local function path_starts_with(path, prefix)
  if path == prefix then
    return true
  end
  return vim.startswith(path, prefix .. '/')
end

function M.get_context(buf)
  buf = buf or 0
  local file = vim.api.nvim_buf_get_name(buf)
  if file == '' or file:match('^%a+://') or vim.bo[buf].buftype ~= '' then
    return nil
  end

  local dir = vim.fs.dirname(file)
  local code, stdout = execute({ 'git', 'rev-parse', '--show-toplevel' }, dir)
  if code == 0 then
    local root = vim.trim(stdout)
    local relpath = vim.fs.relpath(root, file)
    if relpath ~= nil then
      return {
        cwd = root,
        relpath = relpath,
        git_cmd = { 'git' },
      }
    end
  end

  local home = vim.env.HOME
  local git_dir = home and (home .. '/.dotfile') or nil
  if home == nil or git_dir == nil then
    return nil
  end
  if not path_starts_with(file, home) or vim.uv.fs_stat(git_dir) == nil then
    return nil
  end

  local relpath = vim.fs.relpath(home, file)
  if relpath == nil then
    return nil
  end

  local git_cmd = {
    'git',
    '--git-dir=' .. git_dir,
    '--work-tree=' .. home,
  }
  local exists = execute(vim.list_extend(vim.deepcopy(git_cmd), {
    'ls-files',
    '--error-unmatch',
    '--',
    relpath,
  }), home)
  if exists ~= 0 then
    return nil
  end

  return {
    cwd = home,
    relpath = relpath,
    git_cmd = git_cmd,
  }
end

function M.run(context, args)
  local cmd = vim.list_extend(vim.deepcopy(context.git_cmd), args)
  return execute(cmd, context.cwd)
end

return M
