module Foobara
  class Model
    module Concerns
      module Reflection
        include Concern

        module ClassMethods
          def foobara_manifest(to_include: Set.new)
            Util.remove_blank(
              attributes_type: attributes_type.declaration_data,
              organization_name:,
              domain_name:,
              model_name:,
              model_base_class: model_type.declaration_data[:model_base_class],
              model_class: model_type.declaration_data[:model_class]
            )
          end
        end
      end
    end
  end
end
