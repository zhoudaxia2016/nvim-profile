((function_definition
   declarator: (function_declarator
                 declarator: (identifier) @function-name)) @scope-root)

((function_definition
   declarator: (pointer_declarator
                 declarator: (function_declarator
                               declarator: (identifier) @function-name))) @scope-root)

((type_definition
   declarator: (type_identifier) @class-name) @scope-root)

((struct_specifier
   name: (type_identifier) @class-name) @scope-root)

((declaration
   declarator: (init_declarator
                 declarator: (identifier) @object-name)) @scope-root)

((init_declarator
   declarator: (array_declarator
                 declarator: (identifier) @object-name)) @scope-root)

