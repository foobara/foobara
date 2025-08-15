module Foobara
  module BuiltinTypes
    module AssociativeArray
      module SupportedProcessors
        class KeyTypeDeclaration < TypeDeclarations::ElementProcessor
          def key_type
            @key_type ||= type_for_declaration(key_type_declaration)
          end

          def process_value(attributes_hash)
            errors = []

            attributes_hash = attributes_hash.to_a.map.with_index do |(key, value), index|
              key_outcome = key_type.process_value(key)

              if key_outcome.success?
                key = key_outcome.result
              else
                key_outcome.each_error do |error|
                  # Can' prepend path since we dont know if key is a symbolizable type...
                  error.prepend_path!(index, :key)

                  errors << error
                end
              end

              [key, value]
            end.to_h

            Outcome.new(result: attributes_hash, errors:)
          end

          def possible_errors
            super + key_type.possible_errors.map do |possible_error|
                      possible_error = possible_error.dup
                      possible_error.prepend_path!(:"#", :key)
                      possible_error
                    end
          end
        end
      end
    end
  end
end
