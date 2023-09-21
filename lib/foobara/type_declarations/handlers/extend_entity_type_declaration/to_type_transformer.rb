require "foobara/type_declarations/handlers/extend_model_type_declaration/to_type_transformer"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ToTypeTransformer < ExtendModelTypeDeclaration::ToTypeTransformer
          # TODO: need primary key type declaration validator!!!
          def non_processor_keys
            [:primary_key, *super]
          end

          def process_value(strict_declaration_type)
            super.tap do |outcome|
              if outcome.success?
                type = outcome.result

                entity_class = type.target_classes.first

                if entity_class.primary_key_attribute.blank?
                  entity_class.primary_key(strict_declaration_type[:primary_key])
                end
              end
            end
          end
        end
      end
    end
  end
end