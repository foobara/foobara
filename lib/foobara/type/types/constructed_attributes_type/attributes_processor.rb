require "foobara/type/types/constructed_atom_type"

module Foobara
  class Type < Value::Processor
    module Types
      class ConstructedAttributesType < ConstructedAtomType
        class AttributesProcessor < Value::Processor
          def children_types
            declaration_data
          end

          def process(attributes_hash)
            errors = []

            attributes_hash.each_pair do |attribute_name, attribute_value|
              attribute_type = children_types[attribute_name]
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

            children_types.each_pair do |attribute_name, attribute_type|
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
        end
      end
    end
  end
end
