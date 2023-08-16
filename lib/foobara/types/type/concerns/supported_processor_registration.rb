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
          def supported_processor_classes
            @supported_processor_classes ||= {}
          end

          def find_supported_processor_class(processor_symbol)
            unless supported_processor_classes.key?(processor_symbol)
              raise "No such processor for #{processor_symbol}"
            end

            supported_processor_classes[processor_symbol]
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

          def supported_transformer_classes
            supported_processor_classes.select do |_symbol, processor_class|
              processor_class.is_a?(Value::Transformer)
            end
          end

          def supported_validator_classes
            supported_processor_classes.select do |_symbol, processor_class|
              processor_class.is_a?(Value::Validator)
            end
          end
        end
      end
    end
  end
end
