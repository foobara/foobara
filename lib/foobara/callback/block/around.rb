module Foobara
  module Callback
    class Block
      class Around < Block
        include Concerns::KeywordArgumentableBlock
        include Concerns::BlockParameterRequired
      end
    end
  end
end
