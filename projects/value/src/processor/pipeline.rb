Foobara::Util.require_project_file("value/processor/multi")

module Foobara
  module Value
    class Processor
      class Pipeline < Multi
        class << self
          def manifest
            # :nocov:
            super.merge(processor_type: :pipeline)
            # :nocov:
          end
        end

        def process_outcome(old_outcome)
          processors.inject(old_outcome) do |outcome, processor|
            processor.process_outcome(outcome)
          end
        end

        def process_value(value)
          process_outcome(Outcome.success(value))
        end
      end
    end
  end
end
