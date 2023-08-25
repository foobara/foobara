require "foobara/value/processor/multi"

module Foobara
  module Value
    class Processor
      class Pipeline < Multi
        # TODO: can we get away with overriding process instead?
        def process_outcome(old_outcome)
          return old_outcome unless applicable?(old_outcome.result)
          return old_outcome if old_outcome.is_a?(Value::HaltedOutcome)

          processors.inject(old_outcome) do |outcome, processor|
            if processor.applicable_for_outcome?(outcome)
              processor.process_outcome(outcome)
            else
              outcome
            end
          end
        end
      end
    end
  end
end
