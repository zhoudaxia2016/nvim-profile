; Array
((pair
    key: (string (string_content) @array-name)
    value: (array)) @scope-root)

; Object
((pair
    key: (string (string_content) @object-name)
    value: (object)) @scope-root)

; Null
((pair
    key: (string (string_content) @null-name)
    value: (null)) @scope-root)

; Boolean
((pair
    key: (string (string_content) @boolean-name)
    value: ([(false) (true)])) @scope-root)

; Number
((pair
    key: (string (string_content) @number-name)
    value: (number)) @scope-root)

; String
((pair
    key: (string (string_content) @string-name)
    value: (string)) @scope-root)
