module Foobara
  module BuiltinTypes
    module AssociativeArray
      module SupportedProcessors
        class ValueTypeDeclaration < TypeDeclarations::ElementProcessor
          def value_type
            @value_type ||= type_for_declaration(value_type_declaration)
          end

          def process_value(attributes_hash)
            errors = []

            attributes_hash = attributes_hash.to_a.map.with_index do |(key, value), index|
              value_outcome = value_type.process_value(value)

              if value_outcome.success?
                value = value_outcome.result
              else
                value_outcome.each_error do |error|
                  # Can' prepend path since we dont know if key is a symbolizable type...
                  error.prepend_path!(index, :value)

                  errors << error
                end
              end

              [key, value]
            end.to_h

            Outcome.new(result: attributes_hash, errors:)
          end

          def possible_errors
            super + value_type.possible_errors.map do |possible_error|
                      possible_error = possible_error.dup
                      possible_error.prepend_path!(:"#", :value)
                      possible_error
                    end
          end
        end
      end
    end
  end
end
