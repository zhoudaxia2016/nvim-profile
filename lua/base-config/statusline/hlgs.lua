local hlgs = {
  a = {
    name = 'statusline_a',
    fg = '#3B4252',
    bg = '#88C0D0'
  },
  b = {
    name = 'statusline_b',
    fg = '#E5E9F0',
    bg = '#3B4252'
  },
  c = {
    name = 'statusline_c',
    fg = '#E5E9F0',
    bg = '#4C566A'
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
  fg = '#BF616A',
  bg = hlgs.c.bg
}
hlgs.warn = {
  name = 'statusline_warn',
  fg = '#EBCB8B',
  bg = hlgs.c.bg
}
hlgs.info = {
  name = 'statusline_info',
  fg = '#88C0D0',
  bg = hlgs.c.bg
}

return hlgs
