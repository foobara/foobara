module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendRegisteredModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class MutableValidator < TypeDeclarations::TypeDeclarationValidator
          class InvalidMutableValueGivenError < Value::DataError
            class << self
              def context_type_declaration
                {
                  invalid_key: :symbol,
                  valid_attribute_names: [:symbol],
                  mutable: [:symbol]
                }
              end
            end
          end

          def applicable?(value)
            value.key?(:mutable)
          end

          def validation_errors(strict_type_declaration)
            mutable = strict_type_declaration[:mutable]
            return if mutable == true || mutable == false

            model_type = strict_type_declaration.type

            model_type ||= type_for_declaration(strict_type_declaration[:type])

            valid_attribute_names = model_type.element_types.element_types.keys

            mutable.map do |key|
              unless valid_attribute_names.include?(key)
                build_error(
                  message: "#{key} is not a valid attribute, expected one of #{valid_attribute_names}",
                  context: {
                    invalid_key: key,
                    valid_attribute_names:,
                    mutable:
                  }
                )
              end
            end.compact
          end
        end
      end
    end
  end
end
