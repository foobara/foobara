module Foobara
  module Callback
    class Block
      class Before < Block
        include Concerns::KeywordArgumentableBlock
        include Concerns::BlockParameterNotAllowed
      end
    end
  end
end
