module Foobara
  module Types
    class TypeDeclaration < Type
      module Concerns
        # What do we actually need here?
        # we need a way to associate a type with a collection of supported processors.
        # Type could make the most sense for this functionality.
        # Any reason we should be decoupling the concept of validators to apply
        # from validators that are supported and may or may not be applied?
        # OK let's attempt doing this on Type instead.
        module ProcessorRegistries
          extend ActiveSupport::Concern

          class_methods do
            def supported_processor_classes
              @supported_processor_classes ||= {}
            end

            def register_supported_processor_class(processor_class)
              symbol = processor_class.symbol

              if !symbol.is_a?(Symbol) || supported_processor_classes.key?(symbol)
                # :nocov:
                raise "#{processor_class} has an invalid symbol: #{symbol.inspect}. Should instead be a symbol."
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

            def autoregister_processors
              # TODO: what hte hell is type here?
              module_symbol = type.to_s.camelize.to_sym

              transformer_module = Util.constant_value(Types::Transformers, module_symbol)

              if transformer_module
                Util.constant_values(transformer_module, is_a: Class).each do |transformer_class|
                  register_supported_processor_class(transformer_class)
                end
              end

              validator_module = Util.constant_value(Types::Validators, module_symbol)

              if validator_module
                Util.constant_values(validator_module, is_a: Class).each do |validator_class|
                  register_supported_processor_class(validator_class)
                end
              end
            end
          end
        end
      end
    end
  end
end
