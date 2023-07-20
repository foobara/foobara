require "foobara/callback/block"

module Foobara
  module Callback
    class BeforeBlock < Block
      include KeywordArgumentableBlock
      include BlockParameterNotAllowed
    end
  end
end
