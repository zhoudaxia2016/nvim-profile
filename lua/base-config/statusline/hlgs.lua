local palettes = require('nord.named_colors')
local dark_gray = palettes.dark_gray
local off_blue = palettes.off_blue
local darker_white = palettes.darker_white
local light_gray = palettes.light_gray
local red = palettes.red
local yellow = palettes.yellow

local hlgs = {
  a = {
    name = 'statusline_a',
    fg = dark_gray,
    bg = off_blue
  },
  b = {
    name = 'statusline_b',
    fg = darker_white,
    bg = dark_gray
  },
  c = {
    name = 'statusline_c',
    fg = darker_white,
    bg = light_gray
  }
}

hlgs.aTob = {
  name = 'statusline_a_to_b',
  fg = hlgs.a.bg,
  bg = hlgs.b.bg
}
hlgs.bToa = {
  name = 'statusline_b_to_a',
  fg = hlgs.b.bg,
  bg = hlgs.a.bg
}
hlgs.bToc = {
  name = 'statusline_b_to_c',
  fg = hlgs.b.bg,
  bg = hlgs.c.bg
}
hlgs.cTob = {
  name = 'statusline_c_to_b',
  fg = hlgs.c.bg,
  bg = hlgs.b.bg
}
hlgs.error = {
  name = 'statusline_error',
  fg = red,
  bg = hlgs.c.bg
}
hlgs.warn = {
  name = 'statusline_warn',
  fg = yellow,
  bg = hlgs.c.bg
}
hlgs.info = {
  name = 'statusline_info',
  fg = off_blue,
  bg = hlgs.c.bg
}

return hlgs
