local border_chars = {
  TOP_LEFT = '┌',
  TOP_RIGHT = '┐',
  MID_HORIZONTAL = '─',
  MID_VERTICAL = '│',
  BOTTOM_LEFT = '└',
  BOTTOM_RIGHT = '┘',
}

local function select_callback(index, line)
  -- function job here
end

local function close_callback(index, line)
  -- function job here
end

Opts = {
  height = 5,
  width = 10,
  mode = 'editor',
  close_on_bufleave = true,
  data = {'hello', 'world'}, -- Read below how to provide this.
  keymaps = {
    i = {
      ['<Cr>'] = function(popup)
        popup:close(select_callback)
      end
    },
    n = {
      ['<Cr>'] = function(popup)
        popup:close(select_callback)
      end
    }
  },
  callbacks = {
    select = select_callback, -- automatically calls it when selection changes
    close = close_callback, -- automatically calls it when window closes.
  },
  list = {
    border = true,
    numbering = true,
    title = 'MyTitle',
    border_chars = border_chars,
    highlight = 'Normal',
    selection_highlight = 'Visual',
    matching_highlight = 'Identifier',
  },
}

vim.api.nvim_set_keymap('n', '<leader>p', ':lua require"popfix":new(Opts)<cr>', {})
