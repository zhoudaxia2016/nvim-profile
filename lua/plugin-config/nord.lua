local palettes = require('nord.named_colors')
local loadColorSet = require('nord.util').loadColorSet
palettes = vim.tbl_extend('error', palettes, {
  greyBlue = '#a1bad0',
  lightGreen = '#bbded6',
  skin = '#ecd6c7',
  darkGreen = '#518f8b',
})

local themes = {
  ['@parameter'] = { fg = palettes.greyBlue },
  ['@lsp.type.parameter'] = { fg = palettes.greyBlue },
  ['@lsp.type.typeParameter'] = { fg = palettes.greyBlue },
  ['@constructor'] = { fg = palettes.lightGreen },
  ['@lsp.type.class'] = { fg = palettes.lightGreen },
  ['@lsp.type.property'] = { fg = palettes.blue },
  ['@conditional'] = { fg = palettes.skin },
  ['@variable.builtin'] = { fg = palettes.darkGreen },
  ['@string.regex'] = { fg = palettes.purple },
  ['@lsp.type.enumMember'] = { fg = palettes.yellow },
  ['@lsp.mod.defaultLibrary'] = { fg = palettes.darkGreen },
  ['@lsp.typemod.variable.local'] = { fg = palettes.darkest_white },
  ['@lsp.type.variable'] = { fg = palettes.white },
  ['@variable'] = { fg = palettes.darkest_white },
  ['LspInlayHint'] = { fg = '#616e88' },
  Folded = { bg = '#474E68' },

  -- markdown
  ['@h1'] = { bg = '#8ea9a4 ', fg = '#666666' },
  ['@h2'] = { bg = '#a0c0ba ', fg = '#555555' },
  ['@h3'] = { bg = '#b7cdce ', fg = '#444444' },
  ['@h4'] = { bg = '#cfdcdd ', fg = '#333333' },
  ['@h5'] = { bg = '#e0e6eb ', fg = '#222222' },
  ['@markup.strong'] = { style = 'reverse' },
  ['@markup.raw'] = { fg = palettes.purple },

  -- diff
  ['DiffAdd'] = { bg = '#495959' },
  ['DiffDelete'] = { bg = '#582a33' },
  ['DiffChange'] = { bg = '#474E68' },
  ['DiffText'] = { bg = '#604464' },

  -- menu
  ['PmenuSel'] = { bg = palettes.off_blue, fg = palettes.gray },
}

vim.cmd[[
  hi CursorLine gui=underline
]]

loadColorSet(themes)
