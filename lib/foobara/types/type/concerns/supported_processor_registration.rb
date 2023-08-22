module Foobara
  module Types
    class Type < Value::Processor::Pipeline
      module Concerns
        # What do we actually need here?
        # we need a way to associate a type with a collection of supported processors.
        # Type could make the most sense for this functionality.
        # Any reason we should be decoupling the concept of validators to apply
        # from validators that are supported and may or may not be applied?
        # OK let's attempt doing this on Type instead.
        module SupportedProcessorRegistration
          class MissingProcessorError < StandardError
          end

          def supported_processor_classes
            @supported_processor_classes ||= {}
          end

          def find_supported_processor_class(processor_symbol)
            if supported_processor_classes.key?(processor_symbol)
              supported_processor_classes[processor_symbol]
            elsif base_type
              base_type.find_supported_processor_class(processor_symbol)
            else
              # TODO: can we catch this via a type declaration validator before hitting it here?
              raise MissingProcessorError, "No such processor for #{processor_symbol}"
            end
          end

          def register_supported_processor_class(processor_class, symbol: processor_class.symbol)
            if !symbol.is_a?(Symbol) || supported_processor_classes.key?(symbol)
              # :nocov:
              raise "invalid symbol given or #{processor_class} has an invalid symbol: #{symbol.inspect}. " \
                    "Should instead be a symbol."
              # :nocov:
            end

            supported_processor_classes[symbol] = processor_class
          end
        end
      end
    end
  end
end
