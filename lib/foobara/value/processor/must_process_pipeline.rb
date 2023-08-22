require "foobara/value/processor/pipeline"
require "foobara/value/attribute_error"

module Foobara
  module Value
    class Processor
      class MustProcessPipeline < Pipeline
        class UnableToProcessError < AttributeError
          class << self
            def context_type_declaration
              {
                value: :duck,
                processor_names: :duck
              }
            end
          end
        end

        def error_message(value)
          "Expected at least one of #{processor_names.join(",")} to be able to process #{value.inspect} but none could"
        end

        def error_context(value)
          {
            value:,
            processor_names:
          }
        end

        # TODO: can we get away with overriding process instead?
        def process_outcome(old_outcome)
          if applicable?(old_outcome.result)
            super
          else
            Value::HaltedOutcome.errors(build_error(UnableToProcessError))
          end
        end
      end
    end
  end
end
