module Foobara
  module Callback
    class Block
      class After < Block
        include Concerns::KeywordArgumentableBlock
        include Concerns::BlockParameterNotAllowed
      end
    end
  end
end
