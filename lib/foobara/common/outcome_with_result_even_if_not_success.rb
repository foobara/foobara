require "foobara/common/outcome"

module Foobara
  class OutcomeWithResultEvenIfNotSuccess < Outcome
    attr_reader :result
  end
end
