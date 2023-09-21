Foobara.require_file("type_declarations", "handlers/extend_model_type_declaration/model_class_desugarizer")

module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendEntityTypeDeclaration < ExtendModelTypeDeclaration
        class PrimaryKeyDesugarizer < Desugarizer
          def applicable?(sugary_type_declaration)
            primary_key = sugary_type_declaration[:primary_key]

            primary_key.present? && primary_key.is_a?(::String)
          end

          def desugarize(sugary_type_declaration)
            sugary_type_declaration.merge(primary_key: sugary_type_declaration[:primary_key].to_sym)
          end
        end
      end
    end
  end
end
