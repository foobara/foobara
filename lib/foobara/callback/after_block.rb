module Foobara
  module Callback
    class AfterBlock < Block
      include KeywordArgumentableBlock
      include BlockParameterNotAllowed
    end
  end
end
