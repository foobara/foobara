module Foobara
  module BuiltinTypes
    module Entity
      module Casters
        class PrimaryKey < Value::Caster
          class << self
            def requires_declaration_data?
              true
            end

            def requires_type?
              true
            end
          end

          def entity_class
            declaration_data.target_class
          end

          def primary_key_type
            entity_class.primary_key_type
          end

          def applicable?(value)
            primary_key_type.applicable?(value)
          end

          def transform(primary_key)
            entity_class.thunk(primary_key)
          end

          def applies_message
            primary_key_type.value_caster.applies_message
          end
        end
      end
    end
  end
end