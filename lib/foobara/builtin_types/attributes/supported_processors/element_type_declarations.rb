module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedProcessors
        class ElementTypeDeclarations < TypeDeclarations::ElementProcessor
          class UnexpectedAttributesError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  unexpected_attributes: [:symbol],
                  allowed_attributes: [:symbol]
                }
              end
            end
          end

          def element_type_declarations
            declaration_data
          end

          def allowed_attributes
            @allowed_attributes ||= declaration_data.keys
          end

          def process(attributes_hash)
            unexpected_attributes = attributes_hash.keys - allowed_attributes

            if unexpected_attributes.present?
              # unexpected_attribute_errors = unexpected_attributes.map do |unexpected_attribute_name|
              unexpected_attributes_error = build_error(
                attributes_hash,
                message: "Unexpected attributes #{
                  unexpected_attributes
                }. Expected only #{allowed_attributes}",
                context: {
                  unexpected_attributes:,
                  allowed_attributes:
                }
              )

              return Foobara::Value::HaltedOutcome.error(unexpected_attributes_error)
            end

            errors = []

            attributes_hash.each_pair do |attribute_name, attribute_value|
              attribute_type_declaration = element_type_declarations[attribute_name]
              attribute_type = type_for_declaration(attribute_type_declaration)
              attribute_outcome = attribute_type.process(attribute_value)

              if attribute_outcome.success?
                attributes_hash[attribute_name] = attribute_outcome.result
              else
                attribute_outcome.each_error do |error|
                  error.path = [attribute_name, *error.path]

                  errors << error
                end
              end
            end

            Outcome.new(result: attributes_hash, errors:)
          end

          def possible_errors
            possibilities = super

            element_type_declarations.each_pair do |attribute_name, attribute_declaration|
              attribute_type = type_for_declaration(attribute_declaration)

              attribute_type.possible_errors.each_pair do |key, error_class|
                key = ErrorKey.prepend_path(key, attribute_name)

                possibilities[key] = error_class
              end
            end

            possibilities
          end
        end
      end
    end
  end
end
