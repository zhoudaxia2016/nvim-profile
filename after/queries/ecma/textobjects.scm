(object
  [(pair) (spread_element)] @pair.inner
  ","? @_end .
 (#make-range! "pair.outer" @pair.inner @_end ))

(object
  "," @_start .
  [(pair) (spread_element)] @pair.inner
 (#make-range! "pair.outer" @_start @pair.inner))

(function_declaration) @block.outer

(export_statement
  (function_declaration) @block.outer) @block.outer.start

(arrow_function) @block.outer

(method_definition) @block.outer

(class_declaration) @block.outer

(export_statement
  (class_declaration) @block.outer) @block.outer.start

(for_in_statement) @block.outer
(for_statement) @block.outer

(while_statement) @block.outer

(do_statement) @block.outer

(if_statement) @block.outer

(switch_statement) @block.outer

