(list
  (anonymous_node)+ @keyword
  (capture
    name: (identifier) @id)
  (#match? @id "^(keyword|include|conditional|repeat|exception)")
)
