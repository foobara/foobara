require "foobara/value/processor/multi"
require "foobara/value/attribute_error"

module Foobara
  module Value
    class Processor
      class Selection < Multi
        class NoApplicableProcessorError < AttributeError
          class << self
            def context_type_declaration
              {
                processors: :duck,
                value: :duck
              }
            end
          end
        end

        class MoreThanOneApplicableProcessorError < AttributeError
          class << self
            def context_type_declaration
              {
                processors: :duck,
                applicable_processors: :duck,
                value: :duck
              }
            end
          end
        end

        attr_accessor :enforce_unique

        def initialize(*args, enforce_unique: true, **opts)
          self.enforce_unique = enforce_unique
          super(*args, **opts)
        end

        def process_outcome(old_outcome)
          if old_outcome.is_a?(Value::HaltedOutcome)
            old_outcome
          else
            process(old_outcome.result)
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
          processor = if enforce_unique
                        applicable_processors = processors.select { |p| p.applicable?(value) }

                        if applicable_processors.size > 1
                          return Outcome.error(
                            build_error(
                              value,
                              error_class: MoreThanOneApplicableProcessorError,
                              message: "More than one processor applicable for #{value}",
                              context: error_context(value).merge(applicable_processors:)
                            )
                          )
                        end

                        applicable_processors.first
                      else
                        processors.find { |processor| processor.applicable?(value) }
                      end

          if processor.blank?
            Outcome.error(
              build_error(value, error_class: NoApplicableProcessorError)
            )
          else
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
          # TODO: should override this message so we say registry or caster or whatever based on the situation
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
