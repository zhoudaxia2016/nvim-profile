; inherits: ecma

; Class
((class_declaration
  name: (identifier) @class-name
  body: (class_body)) @scope-root)

; Arrow Function
((variable_declarator
  name: (identifier) @function-name
  value: (arrow_function)) @scope-root)

; Function Expression
((variable_declarator
  name: (identifier) @function-name
  value: (function_expression)) @scope-root)

; Tests
((expression_statement
  (call_expression
    function: (identifier)
    arguments: (arguments
      (string) @method-name
      (arrow_function)))) @scope-root)

; Arrow function methods
((field_definition
  property: (property_identifier) @method-name
  value: (arrow_function)) @scope-root)
