module Foobara
  module Callback
    class Block
      class Around < Block
        include KeywordArgumentableBlock
        include BlockParameterRequired
      end
    end
  end
end
