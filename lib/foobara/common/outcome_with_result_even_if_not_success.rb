require "foobara/common/outcome"

module Foobara
  class OutcomeWithResultEvenIfNotSuccess < Outcome
    class << self
      def merge(outcomes)
        merged_outcome = Outcome.merge(outcomes)

        unless merged_outcome.success?
          merged_outcome.result ||= outcomes.map(&:result).compact.last
        end
      end
    end

    attr_reader :result
  end
end
