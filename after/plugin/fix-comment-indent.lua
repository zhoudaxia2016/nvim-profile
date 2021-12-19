-- issue https://github.com/nvim-treesitter/nvim-treesitter/issues/1167
function _G.javascript_indent()
  local line = vim.fn.getline(vim.v.lnum)
  local prev_line = vim.fn.getline(vim.v.lnum - 1)
  if line:match('^%s*[%*/]%s*') then
    if prev_line:match('^%s*%*%s*') then
      return vim.fn.indent(vim.v.lnum - 1)
    end
    if prev_line:match('^%s*/%*%*%s*$') then
      return vim.fn.indent(vim.v.lnum - 1) + 1
    end
  end

  return vim.fn['nvim_treesitter#indent']()
end

local ft = { 'javascript', 'typescript', 'typescriptreact' }
vim.api.nvim_command("au Filetype " .. table.concat(ft, ',') .. " setlocal indentexpr=v:lua.javascript_indent()")
