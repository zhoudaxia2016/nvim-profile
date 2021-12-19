(object
  [(pair) (spread_element)] @pair.inner
  ","? @_end .
 (#make-range! "pair.outer" @pair.inner @_end ))

(object
  "," @_start .
  [(pair) (spread_element)] @pair.inner
 (#make-range! "pair.outer" @_start @pair.inner))
