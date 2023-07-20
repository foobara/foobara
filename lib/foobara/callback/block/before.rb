module Foobara
  module Callback
    class Block
      class Before < Block
        include KeywordArgumentableBlock
        include BlockParameterNotAllowed
      end
    end
  end
end
