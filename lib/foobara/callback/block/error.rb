module Foobara
  module Callback
    class Block
      class Error < Block
        include SingleArgumentBlock
        include BlockParameterNotAllowed
      end
    end
  end
end
