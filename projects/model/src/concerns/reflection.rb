module Foobara
  class Model
    module Concerns
      module Reflection
        include Concern

        module ClassMethods
          def foobara_manifest
            remove_sensitive = TypeDeclarations.foobara_manifest_context_remove_sensitive?

            attributes_declaration = foobara_attributes_type.declaration_data

            if remove_sensitive
              attributes_declaration = TypeDeclarations.remove_sensitive_types(attributes_declaration)
            end

            Util.remove_blank(
              attributes_type: attributes_declaration,
              organization_name: foobara_type.foobara_domain.foobara_organization_name,
              domain_name: foobara_type.foobara_domain.foobara_domain_name,
              model_name: foobara_model_name,
              model_base_class: foobara_type.declaration_data[:model_base_class],
              model_class: foobara_type.declaration_data[:model_class],
              delegates:
            )
          end
        end
      end
    end
  end
end
