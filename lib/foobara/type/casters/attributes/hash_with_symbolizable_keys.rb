require "foobara/type/caster"

module Foobara
  class Type
    class Attributes < Type
      module Casters
        class HashWithSymbolizableKeys < Caster
          def cast_from(hash)
            if hash.is_a?(::Hash)
              keys = hash.keys
              non_symbolic_keys = keys.reject { |key| key.is_a?(Symbol) }

              if non_symbolic_keys.empty?
                Outcome.success(hash)
              elsif non_symbolic_keys.all? { |key| key.is_a?(String) }
                Outcome.success(hash.symbolize_keys)
              else
                Outcome.errors(
                  CannotCastError.new(
                    message: "#{hash} contains keys that are not symbolizable: #{non_symbolic_keys}",
                    context: {
                      cast_to_type: type_symbol,
                      value: hash
                    }
                  )
                )
              end
            else
              Outcome.errors(
                CannotCastError.new(
                  message: "#{hash} is not a ::Hash but instead is a #{hash.class}",
                  context: {
                    cast_to_type: type_symbol,
                    value: hash
                  }
                )
              )
            end
          end
        end
      end
    end
  end
end
