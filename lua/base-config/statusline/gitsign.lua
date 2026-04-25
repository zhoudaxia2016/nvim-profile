local gitsign = ''

local function execute(cmd, cwd)
  local result = vim.system(cmd, { text = true, cwd = cwd }):wait()
  return result.code, result.stdout or '', result.stderr or ''
end

local function pathStartsWith(path, prefix)
  if path == prefix then
    return true
  end
  return vim.startswith(path, prefix .. '/')
end

local function getGitContext()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or file:match('^%a+://') or vim.bo.buftype ~= '' then
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
  if pathStartsWith(file, home) == false or vim.uv.fs_stat(git_dir) == nil then
    return nil
  end

  local relpath = vim.fs.relpath(home, file)
  if relpath == nil then
    return nil
  end

  -- Fall back to the fixed bare dotfiles repo only when normal git lookup fails.
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

local function runGit(context, args)
  local cmd = vim.list_extend(vim.deepcopy(context.git_cmd), args)
  return execute(cmd, context.cwd)
end

function GetStatuslineGitsign()
  return gitsign .. ' '
end

function StatuslineGitSign()
  local context = getGitContext()
  if context == nil then
    gitsign = ''
    return
  end

  local code, stdout = runGit(context, {
    'diff',
    '--shortstat',
    'HEAD',
    '--',
    context.relpath,
  })
  if code == 0 and stdout then
    local s = {}
    local addCount = string.match(stdout, '(%d+)%s+%w+%(%+%)')
    if addCount then
      table.insert(s, '++ ' .. addCount)
    end
    local deleteCount = string.match(stdout, '(%d+)%s+%w+%(%-%)')
    if deleteCount then
      table.insert(s, ' ' .. deleteCount)
    end
    gitsign = table.concat(s, ' ')
  else
    gitsign = ''
  end
end

vim.cmd[[au BufEnter,BufWritePost * call v:lua.StatuslineGitSign()]]

return function()
  return gitsign
end
