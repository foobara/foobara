module Foobara
  module BuiltinTypes
    module Array
      module Casters
        class Arrayable < Value::Caster
          def applicable?(value)
            !value.is_a?(::Array) && value.respond_to?(:to_a)
          end

          def applies_message
            "respond to :to_a"
          end

          def cast(object)
            # TODO: This is probably too lenient
            object.to_a
          end
        end
      end
    end
  end
end
