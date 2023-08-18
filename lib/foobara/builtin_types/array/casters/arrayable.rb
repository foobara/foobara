require "foobara/value/caster"

module Foobara
  module BuiltinTypes
    module Array
      module Casters
        class ToArrayable < Value::Caster
          def applicable?(value)
            value.respond_to?(:to_a)
          end

          def applies_message
            "respond to :to_a"
          end

          def cast(object)
            object.to_a
          end
        end
      end
    end
  end
end
