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

            # TODO: do we really need all this stuff? Can't it be grabbed off of the declaration data to save
            # space?
            Util.remove_blank(
              attributes_type: attributes_declaration,
              organization_name: foobara_type.foobara_domain.foobara_organization_name,
              domain_name: foobara_type.foobara_domain.foobara_domain_name,
              model_name: foobara_model_name,
              model_base_class: foobara_type.declaration_data[:model_base_class],
              model_class: foobara_type.declaration_data[:model_class],
              delegates: foobara_delegates_manifest,
              private: foobara_private_attribute_names
            )
          end

          private

          def foobara_delegates_manifest
            if foobara_delegates&.any?
              manifest = foobara_delegates.dup
              guaranteed_to_exist = []

              delegates.each_pair do |attribute_name, delegate_manifest|
                data_path = DataPath.for(delegate_manifest[:data_path])

                if delegate_guaranteed_to_exist?(data_path)
                  guaranteed_to_exist << attribute_name
                end
              end

              if guaranteed_to_exist.any?
                manifest[:guaranteed_to_exist] = guaranteed_to_exist
              end

              manifest
            end
          end

          def delegate_guaranteed_to_exist?(data_path)
            parent_path = data_path.parent
            return true unless parent_path

            return false unless delegate_guaranteed_to_exist?(parent_path)

            parent_type = model_type.type_at_path(parent_path)

            parent_type = if parent_type.extends?(BuiltinTypes[:model])
                            parent_type.target_class.attributes_type
                          elsif parent_type.extends?(BuiltinTypes[:attributes])
                            parent_type
                          end

            return true unless parent_type

            symbol = data_path.last

            parent_declaration_data = parent_type.declaration_data

            parent_declaration_data[:required]&.include?(symbol) ||
              parent_declaration_data[:defaults]&.key?(symbol)
          end
        end
      end
    end
  end
end
