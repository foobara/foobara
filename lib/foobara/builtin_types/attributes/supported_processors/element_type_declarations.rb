module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedProcessors
        class ElementTypeDeclarations < TypeDeclarations::ElementProcessor
          class UnexpectedAttributeError < Foobara::Value::DataError
            class << self
              def context_type_declaration
                {
                  attribute_name: :symbol,
                  value: :duck,
                  allowed_attributes: :duck # TODO: update with :array
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

            unexpected_attribute_errors = unexpected_attributes.map do |unexpected_attribute_name|
              build_error(
                attributes_hash,
                message: "Unexpected attributes #{
                  unexpected_attribute_name
                }. Expected only #{allowed_attributes}",
                context: {
                  attribute_name: unexpected_attribute_name,
                  value: attributes_hash[unexpected_attribute_name],
                  allowed_attributes:
                }
              )
            end

            if unexpected_attribute_errors.present?
              return Foobara::Value::HaltedOutcome.errors(unexpected_attribute_errors)
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

              attribute_type.possible_errors.each do |possible_error|
                path = possible_error[0]
                symbol = possible_error[1]
                error_class = possible_error[2]

                possibilities << [
                  [attribute_name, *path],
                  symbol,
                  error_class
                ]
              end
            end

            possibilities
          end
        end
      end
    end
  end
end
