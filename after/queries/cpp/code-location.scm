; inherits: c

; ---- 命名空间 ----
((namespace_definition
   name: (namespace_identifier) @class-name) @scope-root)

((namespace_definition
   name: (nested_namespace_specifier) @class-name) @scope-root)

; ---- class / enum / using（struct 已由 c 覆盖）----
((class_specifier
   name: (type_identifier) @class-name) @scope-root)

((enum_specifier
   name: (type_identifier) @class-name) @scope-root)

((alias_declaration
   name: (type_identifier) @class-name) @scope-root)

; ---- 类外成员函数定义 Class::func（含任意层限定名、构造函数、析构、运算符重载）----
((function_definition
   declarator: (function_declarator
                 declarator: (_) @method-name)) @scope-root)

; ---- 类外成员函数定义（指针返回）T* Class::func ----
((function_definition
   declarator: (pointer_declarator
                 declarator: (function_declarator
                               declarator: (_) @method-name))) @scope-root)

; ---- 类外成员函数定义（引用返回）T& Class::func ----
((function_definition
   declarator: (reference_declarator
                 (function_declarator
                   declarator: (_) @method-name))) @scope-root)

; ---- 类内方法声明：void f(); / int* f(); ----
((field_declaration
   declarator: (function_declarator
                 declarator: (field_identifier) @method-name)) @scope-root)

((field_declaration
   declarator: (pointer_declarator
                 declarator: (function_declarator
                               declarator: (field_identifier) @method-name))) @scope-root)

; ---- 类内成员变量 ----
((field_declaration
   declarator: (field_identifier) @object-name) @scope-root)
