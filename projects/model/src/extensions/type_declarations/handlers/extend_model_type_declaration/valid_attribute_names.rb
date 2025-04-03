module Foobara
  module TypeDeclarations
    module Handlers
      class ExtendModelTypeDeclaration < ExtendRegisteredTypeDeclaration
        class ValidAttributeNames < TypeDeclarations::TypeDeclarationValidator
          class InvalidPrivateValueGivenError < Value::DataError
            class << self
              def context_type_declaration
                {
                  invalid_attribute_name: :symbol,
                  valid_attribute_names: [:symbol],
                  private: :array
                }
              end

              def fatal?
                # Since there could be multiple bad private
                true
              end
            end
          end

          def applicable?(strict_type_declaration)
            private = strict_type_declaration[:private]

            private.is_a?(::Array) && Util.all_symbolic_elements?(private)
          end

          def validation_errors(strict_type_declaration)
            private = strict_type_declaration[:private]

            attributes_declaration = strict_type_declaration[:attributes_declaration]
            valid_attribute_names = attributes_declaration[:element_type_declarations].keys

            # TODO: this should be one error instead of multiple
            private.map do |element|
              unless valid_attribute_names.include?(element)
                build_error(
                  message: "#{element} is not a valid private attribute name, " \
                           "expected one of #{valid_attribute_names}",
                  context: {
                    invalid_attribute_name: element,
                    valid_attribute_names:,
                    private:
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
