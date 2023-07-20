module Foobara
  module Callback
    class AfterBlock < BaseBlock
      include KeywordArgumentableBlock
      include BlockParameterNotAllowed
    end
  end
end
