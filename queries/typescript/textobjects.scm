; inherits: ecma

; pair
(enum_body
  (enum_assignment) @pair.inner
  ","? @_end .
 (#make-range! "pair.outer" @pair.inner @_end ))

(enum_body
  "," @_start .
  (enum_assignment) @pair.inner
 (#make-range! "pair.outer" @_start @pair.inner))

(object_type
  (property_signature) @pair.inner
  ","? @_end .
 (#make-range! "pair.outer" @pair.inner @_end ))

(object_type
  "," @_start .
  (property_signature) @pair.inner
 (#make-range! "pair.outer" @_start @pair.inner))

(named_imports
  (import_specifier) @pair.inner
  ","? @_end .
 (#make-range! "pair.outer" @pair.inner @_end ))

(named_imports
  "," @_start .
  (import_specifier) @pair.inner
 (#make-range! "pair.outer" @_start @pair.inner))

(formal_parameters (_) @argument)
