module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendDetachedEntityTypeDeclaration
        class ToTypeTransformer < ExtendDetachedEntityTypeDeclaration::ToTypeTransformer
          def process_value(strict_declaration_type)
            super.tap do |outcome|
              if outcome.success?
                type = outcome.result
                entity_class = type.target_class

                unless entity_class.can_be_created_through_casting?
                  type.remove_caster_instances_of(Foobara::BuiltinTypes::Entity::Casters::Hash)
                end
              end
            end
          end
        end
      end
    end
  end
end
