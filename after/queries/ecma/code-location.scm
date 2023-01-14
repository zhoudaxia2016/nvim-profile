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

; Function
((function_declaration
  name: (identifier) @function-name
  body: (statement_block)) @scope-root)

; Method
((method_definition
  name: (property_identifier) @method-name
  body: (statement_block)) @scope-root)
