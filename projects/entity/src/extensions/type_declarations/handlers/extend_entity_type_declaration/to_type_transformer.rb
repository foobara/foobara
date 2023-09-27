module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ToTypeTransformer < ExtendModelTypeDeclaration::ToTypeTransformer
          class EntityPrimaryKeyCaster < Value::Caster
            class << self
              def requires_declaration_data?
                true
              end
            end

            def entity_class
              declaration_data
            end

            def applicable?(value)
              entity_class.primary_key_type.applicable?(value)
            end

            def transform(primary_key)
              entity_class.thunk(primary_key)
            end
          end

          def non_processor_keys
            [:primary_key, *super]
          end

          def process_value(strict_declaration_type)
            super.tap do |outcome|
              if outcome.success?
                type = outcome.result

                entity_class = type.target_class

                unless entity_class.primary_key_attribute
                  entity_class.primary_key(strict_declaration_type[:primary_key])
                end

                type.casters << EntityPrimaryKeyCaster.new(entity_class)
              end
            end
          end
        end
      end
    end
  end
end
