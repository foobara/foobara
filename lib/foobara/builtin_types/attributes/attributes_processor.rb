module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedProcessors
        class ElementTypeDeclarations < Types::ElementProcessor
          include TypeDeclarations::WithRegistries

          def element_type_declarations
            declaration_data
          end

          def process(attributes_hash)
            return Outcome.success(attributes_hash) unless applicable?(attributes_hash)

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
            possibilities = []

            element_type_declarations.each_pair do |attribute_name, attribute_declaration|
              attribute_type = type_for_declaration(attribute_declaration)

              attribute_type.possible_errors.each do |possible_error|
                path = possible_error[0]
                symbol = possible_error[1]
                error_type = possible_error[2]

                possibilities << [
                  [attribute_name, *path],
                  symbol,
                  error_type
                ]
              end
            end

            possibilities
          end

          def priority
            Priority::LOW
          end
        end
      end
    end
  end
end
