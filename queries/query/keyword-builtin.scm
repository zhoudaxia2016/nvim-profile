(list
  (anonymous_node) @keyword
  (capture
    name: (identifier) @id)
  (#match? @id "^(keyword|include|conditional|repeat|exception)")
)

(list
  (named_node name: (identifier) @builtin)
  (capture
    name: (identifier) @id)
  (#match? @id "^(variable\.builtin|constant\.builtin)")
)

(predicate
  name: (identifier) @name (#match? @name "(match|lua-match)")
  parameters: (parameters
    (capture name: (identifier) @type) (#match? @type "(variable\.builtin|function\.builtin)")
    (string) @match.builtin
  )
)

(predicate
  name: (identifier) @name (#match? @name "(eq|any-of)")
  parameters: (parameters
    (capture name: (identifier) @type) (#match? @type "(variable\.builtin|function\.builtin)")
    (string)+ @builtin
  )
)
