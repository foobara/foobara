module Foobara
  module BuiltinTypes
    module Symbol
      module Casters
        class String < Value::Caster
          class << self
            def requires_parent_declaration_data?
              true
            end
          end

          def applicable?(value)
            value.is_a?(::String)
          end

          def applies_message
            "be a String"
          end

          def cast(string)
            string.to_sym
          end
        end
      end
    end
  end
end
