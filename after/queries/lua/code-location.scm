(variable_declaration
  (assignment_statement
    (variable_list (identifier) @function-name)
    (expression_list (function_definition)))) @scope-root

(function_declaration [(identifier) (dot_index_expression)] @function-name) @scope-root

(function_call
  [(identifier) (dot_index_expression)] @call-expression-name) @scope-root

(field [(identifier) (string)] @proper-name) @scope-root
