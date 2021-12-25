local ts_utils = require('nvim-treesitter.ts_utils')
function ToStringEnum()
  local node = ts_utils.get_node_at_cursor(0)
  local enumAssignments = ts_utils.get_named_children(ts_utils.get_named_children(node)[2])
  for _, item in pairs(enumAssignments) do
    local assignment = ts_utils.get_named_children(item)
    if #assignment == 0 then
      local range = ts_utils.node_to_lsp_range(item)
      local text = ts_utils.get_node_text(item)[1]
      vim.lsp.util.apply_text_edits({{ range = range, newText = string.format("%s = '%s'", text, text)}}, 0)
    end
  end
end

vim.api.nvim_buf_set_keymap(0, 'n', '<leader>q', ':call v:lua.ToStringEnum()<cr>', {})
