module Foobara
  module Callback
    class ErrorBlock < Block
      include SingleArgumentBlock
      include BlockParameterNotAllowed
    end
  end
end
