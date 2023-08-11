module Foobara
  class Model
    class Schema
      module Concerns
        module ProcessorRegistries
          extend ActiveSupport::Concern

          class_methods do
            def register_transformer(transformer_class)
              transformers = @transformers ||= {}

              transformers[transformer_class.symbol] = transformer_class
            end

            def transformers
              t = @transformers || {}

              if self == Schema
                t
              else
                t.merge(superclass.transformers)
              end
            end

            def processors
              transformers.merge(validators)
            end

            # Problematic that this is on this class
            def register_validator(validator_class)
              validators = @validators ||= {}

              validators[validator_class.symbol] = validator_class
            end

            def validators
              v = @validators || {}

              if self == Schema
                v
              else
                v.merge(superclass.validators)
              end
            end

            def autoregister_processors
              module_symbol = type.to_s.camelize.to_sym

              transformer_module = Util.constant_value(Types::Transformers, module_symbol)

              if transformer_module
                Util.constant_values(transformer_module, is_a: Class).each do |transformer|
                  register_transformer(transformer)
                end
              end

              validator_module = Util.constant_value(Types::Validators, module_symbol)

              if validator_module
                Util.constant_values(validator_module, is_a: Class).each do |validator|
                  register_validator(validator)
                end
              end
            end
          end

          delegate :validators,
                   :transformers,
                   :processors,
                   to: :class
        end
      end
    end
  end
end
