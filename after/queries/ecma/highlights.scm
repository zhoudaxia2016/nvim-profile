(call_expression
  function: (identifier) @call_expression)

(call_expression
 function: (member_expression
   property: [(property_identifier) (private_property_identifier)] @call_expression))
