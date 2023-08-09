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

                  if error.is_a?(Value::CannotCastError)
                    error_hash = error.to_h.except(:type) # why do we have type here? TODO: fix
                    error_hash[:context][:attribute_name] = attribute_name

                    # Do we really need this translation?? #TODO eliminate somehow
                    error = AttributeError.new(path: [attribute_name], **error_hash)
                  end

                  errors << error
                end
              end
            end

            Outcome.new(result: attributes_hash, errors:)
          end
        end
      end
    end
  end
end
