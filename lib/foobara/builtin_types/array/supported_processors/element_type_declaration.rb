module Foobara
  module BuiltinTypes
    module Array
      module SupportedProcessors
        class ElementTypeDeclaration < TypeDeclarations::ElementProcessor
          def element_type
            @element_type ||= type_for_declaration(element_type_declaration)
          end

          def process_value(array)
            errors = []

            array.each.with_index do |element, index|
              element_outcome = element_type.process_value(element)

              if element_outcome.success?
                array[index] = element_outcome.result
              else
                element_outcome.each_error do |error|
                  error.prepend_path!(index)

                  errors << error
                end
              end
            end

            Outcome.new(result: array, errors:)
          end

          def possible_errors
            possibilities = super

            element_type.possible_errors.each_pair do |key, error_class|
              key = ErrorKey.prepend_path(key, :"#")

              possibilities[key] = error_class
            end

            possibilities
          end
        end
      end
    end
  end
end
