module Foobara
  module Callback
    class Block
      class After < Block
        include KeywordArgumentableBlock
        include BlockParameterNotAllowed
      end
    end
  end
end
