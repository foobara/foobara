module Foobara
  module Callback
    class Block
      class Error < Block
        include Concerns::SingleArgumentBlock
        include Concerns::BlockParameterNotAllowed
      end
    end
  end
end
