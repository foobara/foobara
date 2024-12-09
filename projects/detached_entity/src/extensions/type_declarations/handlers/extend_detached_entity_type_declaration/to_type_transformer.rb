module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendDetachedEntityTypeDeclaration < ExtendModelTypeDeclaration
        class ToTypeTransformer < ExtendModelTypeDeclaration::ToTypeTransformer
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
              end
            end
          end
        end
      end
    end
  end
end
