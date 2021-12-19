((pair
    key: (_) @proper-name
  ) @scope-root)

((call_expression
    function: (_) @call-expression-name
    arguments:
      (arguments ([(function) (arrow_function)]))
  ) @scope-root)

((variable_declarator
  name: (identifier) @object-name
  value: (object)) @scope-root)
