require "foobara/value/processor/multi"

module Foobara
  module Value
    class Processor
      class Selection < Multi
        class NoApplicableProcessorError < Foobara::Error
          class << self
            def context_schema
              {
                processors: :duck,
                value: :duck
              }
            end
          end
        end

        class MoreThanOneApplicableProcessorError < Foobara::Error
          class << self
            def context_schema
              {
                processors: :duck,
                applicable_processors: :duck,
                value: :duck
              }
            end
          end
        end

        def process_outcome(old_outcome)
          if old_outcome.is_a?(Value::HaltedOutcome)
            old_outcome
          else
            process(outcome.result)
          end
        end

        # TODO: move applies_message usage here from casting processor
        def process(value)
          outcome = processor_for(value)

          if outcome.success?
            processor = outcome.result
            outcome = processor.process(value)
          end

          outcome
        end

        def processor_for(value)
          applicable_processors = processors.select { |processor| processor.applicable?(value) }

          error = if applicable_processors.empty?
                    build_error(NoApplicableProcessorError)
                  elsif applicable_processors.size > 1
                    build_error(
                      MoreThanOneApplicableProcessorError,
                      message: "More than one processor applicable for #{value}",
                      context: error_context(value).merge(applicable_processors:)
                    )
                  end

          if error
            Outcome.error(error)
          else
            processor = applicable_processors.first
            Outcome.success(processor)
          end
        end

        def processor_for!(value)
          outcome = processor_for(value)

          outcome.success? ? outcome.result : outcome.raise!
        end

        def always_applicable?
          true
        end

        def error_message(value)
          "Could not find processor that is applicable for #{value}"
        end

        def error_context(value)
          {
            processors: processors.map(&:symbol),
            value:
          }
        end
      end
    end
  end
end
