module Foobara
  module BuiltinTypes
    module Attributes
      module Casters
        class Hash < Value::Caster
          def applicable?(value)
            value.is_a?(::Hash) && value.keys.all? { |key| key.is_a?(::Symbol) || key.is_a?(::String) }
          end

          def applies_message
            "be a hash with symbolizable keys"
          end

          def cast(hash)
            keys = hash.keys
            non_symbolic_keys = keys.reject { |key| key.is_a?(::Symbol) }

            if non_symbolic_keys.empty?
              hash
            else
              Util.symbolize_keys(hash)
            end
          end
        end
      end
    end
  end
end
