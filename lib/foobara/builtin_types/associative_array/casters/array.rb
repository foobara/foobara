require "foobara/builtin_types/casters/direct_type_match"

module Foobara
  module BuiltinTypes
    # TODO: rename to Map to avoid thinking of it as an array of pairs which isn't quite the right mental model.
    module AssociativeArray
      module Casters
        class Array < Value::Caster
          def applicable?(value)
            value.is_a?(::Array) && value.all? { |element| element.size == 2 }
          end

          def applies_message
            "be a an array of pairs"
          end

          def cast(array)
            array.to_h
          end
        end
      end
    end
  end
end
