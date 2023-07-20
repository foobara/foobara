module Foobara
  module Callback
    class ErrorBlock < BaseBlock
      include SingleArgumentBlock
      include BlockParameterNotAllowed
    end
  end
end
