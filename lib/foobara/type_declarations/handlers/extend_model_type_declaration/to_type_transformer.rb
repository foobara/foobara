require "foobara/type_declarations/handlers/registered_type_declaration/to_type_transformer"
require "foobara/type_declarations/handlers/extend_associative_array_type_declaration"

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ToTypeTransformer < ExtendRegisteredTypeDeclaration::ToTypeTransformer
          def process_value(strict_type_declaration)
            super.tap do |outcome|
              if outcome.success?
                outcome.result.manifest_processor = Transformer.create(
                  name: "Make model type declarations serializable",
                  always_applicable?: true,
                  transform: ->(manifest) {
                    manifest = manifest.dup

                    manifest[:declaration_data] = manifest[:declaration_data].transform_values do |value|
                      value.is_a?(::Class) ? value.name : value
                    end

                    manifest[:raw_declaration_data] = manifest[:raw_declaration_data].transform_values do |value|
                      value.is_a?(::Class) ? value.name : value
                    end

                    manifest
                  }
                )
              end
            end
          end

          # TODO: make declaration validator for model_class and model_base_class
          def target_classes(strict_type_declaration)
            strict_type_declaration[:model_class]
          end

          # TODO: must explode if name missing...
          def type_name(strict_type_declaration)
            strict_type_declaration[:name]
          end

          # TODO: create declaration validator for name and the others
          # TODO: seems like a smell that we don't have processors for these?
          def non_processor_keys
            %i[type name model_class model_base_class attributes_declaration]
          end
        end
      end
    end
  end
end
