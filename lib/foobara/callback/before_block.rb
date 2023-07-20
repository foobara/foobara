require "foobara/callback/base_block"

module Foobara
  module Callback
    class BeforeBlock < BaseBlock
      include KeywordArgumentableBlock
      include BlockParameterNotAllowed
    end
  end
end
