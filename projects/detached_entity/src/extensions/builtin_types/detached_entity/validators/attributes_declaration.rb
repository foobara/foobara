module Foobara
  module BuiltinTypes
    module Entity
      module Validators
        class AttributesDeclaration < Model::Validators::AttributesDeclaration
          def applicable?(record)
            record.created? || record.built?
          end

          # Why is this here in entity/ instead of in model/?
          def possible_errors
            return [] if parent_declaration_data == { type: :entity }

            mutable = parent_declaration_data.key?(:mutable) ? parent_declaration_data[:mutable] : false

            if parent_declaration_data.key?(:model_class)
              Object.const_get(parent_declaration_data[:model_class]).possible_errors(mutable:)
            elsif parent_declaration_data[:type] != :entity
              model_type = type_for_declaration(parent_declaration_data[:type])
              model_class = model_type.target_class
              model_class.possible_errors(mutable:)
            else
              # :nocov:
              raise "Missing :model_class in parent_declaration_data for #{parent_declaration_data}"
              # :nocov:
            end
          end
        end
      end
    end
  end
end
