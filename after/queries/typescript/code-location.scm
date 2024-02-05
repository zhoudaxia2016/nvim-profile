; inherits ecma
; Class
((class_declaration
  name: (type_identifier) @class-name
  body: (class_body)) @scope-root)

; Interface
((interface_declaration
  name: (type_identifier) @class-name
  body: (interface_body)) @scope-root)


; Anonymous function
((variable_declarator
  name: (identifier) @function-name
  value: (function_expression
    body: (statement_block))) @scope-root)


; Arrow function
((variable_declarator
  name: (identifier) @function-name
  value: (arrow_function)) @scope-root)

; Describe blocks
((expression_statement
  (call_expression
   function: (identifier)
   arguments: (arguments
     (string) @method-name
     (arrow_function)))) @scope-root)

; Arrow function methods
((public_field_definition
  name: (property_identifier) @method-name
  value: (arrow_function)) @scope-root)
