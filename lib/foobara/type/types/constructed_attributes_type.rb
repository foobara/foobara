require "foobara/type/types/constructed_atom_type"

module Foobara
  class Type < Value::Processor
    module Types
      class ConstructedAttributesType < ConstructedAtomType
        attr_accessor :children_types

        def initialize(children_types: nil, **opts)
          super(**opts)
          self.children_types = children_types
        end

        def process(value)
          # how to know things were halted??
          # For now will go with a hacky Value::HaltedOutcome
          outcome = super

          return outcome if outcome.is_a?(Value::HaltedOutcome)
          return outcome unless children_types.present?

          value = outcome.result

          value.each_pair do |attribute_name, attribute_value|
            attribute_type = children_types[attribute_name]
            attribute_outcome = attribute_type.process(attribute_value)

            if attribute_outcome.success?
              value[attribute_name] = attribute_outcome.result
            else
              attribute_outcome.each_error do |error|
                error.path = [attribute_name, *error.path]

                if error.is_a?(CannotCastError)
                  error_hash = error.to_h.except(:type) # why do we have type here? TODO: fix
                  error_hash[:context][:attribute_name] = attribute_name

                  # Do we really need this translation?? #TODO eliminate somehow
                  error = AttributeError.new(path: [attribute_name], **error_hash)
                end

                outcome.add_error(error)
              end
            end
          end

          outcome
        end
      end
    end
  end
end
