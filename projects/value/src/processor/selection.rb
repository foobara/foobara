require_relative "multi"
require_relative "../data_error"

module Foobara
  module Value
    class Processor
      class Selection < Multi
        class NoApplicableProcessorError < DataError; end
        class MoreThanOneApplicableProcessorError < DataError; end

        class << self
          def foobara_manifest
            # :nocov:
            super.merge(processor_type: :selection)
            # :nocov:
          end
        end

        attr_accessor :enforce_unique, :error_if_none_applicable

        def initialize(*, enforce_unique: true, error_if_none_applicable: true, **)
          self.enforce_unique = enforce_unique
          self.error_if_none_applicable = error_if_none_applicable

          super(*, **)
        end

        # TODO: move applies_message usage here from casting processor
        def process_value(value)
          outcome = processor_for(value)

          if outcome.success?
            processor = outcome.result

            unless processor.nil?
              outcome = processor.process_value(value)
            end
          end

          outcome
        end

        def process_value!(value)
          process_value(value).result!
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
                                applicable_processor_names: applicable_processors.map(&:name)
                              )
                            )
                          )
                        end

                        applicable_processors.first
                      else
                        processors.find { |processor| processor.applicable?(value) }
                      end

          if processor
            Outcome.success(processor)
          elsif error_if_none_applicable
            Outcome.error(build_error(value, error_class: NoApplicableProcessorError))
          else
            Outcome.success(nil)
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
