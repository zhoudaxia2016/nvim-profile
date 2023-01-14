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
  ['@constructor'] = { fg = palettes.lightGreen },
  ['@conditional'] = { fg = palettes.skin },
  ['@variable.builtin'] = { fg = palettes.darkGreen },
  ['@string.regex'] = { fg = palettes.purple },

  -- markdown
  ['@h1'] = { bg = '#8ea9a4 ', fg = '#666666' },
  ['@h2'] = { bg = '#a0c0ba ', fg = '#555555' },
  ['@h3'] = { bg = '#b7cdce ', fg = '#444444' },
  ['@h4'] = { bg = '#cfdcdd ', fg = '#333333' },
  ['@h5'] = { bg = '#e0e6eb ', fg = '#222222' },
}

loadColorSet(themes)
