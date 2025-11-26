require_relative "multi"

module Foobara
  module Value
    class Processor
      class Pipeline < Multi
        class << self
          def foobara_manifest
            # :nocov:
            super.merge(processor_type: :pipeline)
            # :nocov:
          end
        end

        def process_outcome(old_outcome)
          processors.inject(old_outcome) do |outcome, processor|
            return outcome if outcome.fatal?

            value = outcome.result

            if processor.applicable?(value)
              processor.process_outcome(outcome)
            else
              outcome
            end
          end
        end

        def process_value(value)
          process_outcome(Outcome.success(value))
        end
      end
    end
  end
end
