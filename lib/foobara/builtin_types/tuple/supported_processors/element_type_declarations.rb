module Foobara
  module BuiltinTypes
    module Tuple
      module SupportedProcessors
        # TODO: how to relate size to this? I guess a TypeDeclarationValidator is a good idea here to make sure
        # that element_type_declarations.size matches size if both are present and a Desugarizer that sets them both?
        class ElementTypeDeclarations < TypeDeclarations::ElementProcessor
          def applicable?(value)
            # Size mismatch is handled by size validator later so just bail out here since without a correct
            # size we don't really know what to expect to happen if we proceed.
            # TODO: would be nice to have the Size validator run earlier in the process so that we wouldn't have
            # to check this here.
            value.size == element_type_declarations.size
          end

          def element_types
            @element_types ||= element_type_declarations.map do |type_declaration|
              type_for_declaration(type_declaration)
            end
          end

          def process_value(array)
            errors = []

            array.each.with_index do |element, index|
              element_outcome = element_types[index].process_value(element)

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

            element_types.each.with_index do |element_type, index|
              element_type.possible_errors.each_pair do |key, error_class|
                key = ErrorKey.prepend_path(key, index)

                possibilities[key.to_sym] = error_class
              end
            end

            possibilities
          end
        end
      end
    end
  end
end
