require "foobara/value/processor/multi"
require "foobara/value/data_error"

module Foobara
  module Value
    class Processor
      class Selection < Multi
        class NoApplicableProcessorError < DataError; end
        class MoreThanOneApplicableProcessorError < DataError; end

        attr_accessor :enforce_unique

        def initialize(*args, enforce_unique: true, **opts)
          self.enforce_unique = enforce_unique
          super(*args, **opts)
        end

        # TODO: move applies_message usage here from casting processor
        def process_value(value)
          outcome = processor_for(value)

          if outcome.success?
            processor = outcome.result
            outcome = processor.process_value(value)
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
                              context: error_context(value).merge(
                                applicable_processor_names: applicable_processors.map do |processor|
                                                              processor.class.name
                                                            end
                              )
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
          processor_for(value).result!
        end

        def always_applicable?
          true
        end

        def error_message(value)
          # TODO: should override this message so we say registry or caster or whatever based on the situation
          "Could not find processor that is applicable for #{value}"
        end

        # This is a problem... how do we know a base class won't call this for a different error??
        def error_context(value)
          {
            processor_names:,
            value:
          }
        end
      end
    end
  end
end
