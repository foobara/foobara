module Foobara
  class Model
    class TypeBuilder
      module Processors
        module Attribute
          class CastValue < Foobara::Type::ValueProcessor
            attr_accessor :attribute_name, :attribute_type

            def initialize(attribute_name:, attribute_type:)
              super()

              self.attribute_name = attribute_name
              self.attribute_type = attribute_type
            end

            def process_outcome(outcome)
              attributes_hash = outcome.result

              unless attributes_hash.key?(attribute_name)
                # We will assume that other validators will handle the fact that this is missing
                return outcome
              end

              value = attributes_hash[attribute_name]

              cast_outcome = attribute_type.cast_from(value)

              if cast_outcome.success?
                outcome.result = attributes_hash.merge(attribute_name => cast_outcome.result)
              else
                cast_outcome.errors.each do |error|
                  outcome.add_error(error)
                end
              end
            end
          end
        end
      end
    end
  end
end
