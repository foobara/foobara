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

              process_outcome = attribute_type.process(value)

              if process_outcome.success?
                outcome.result = attributes_hash.merge(attribute_name => process_outcome.result)
              else
                process_outcome.errors.each do |error|
                  attribute_error = AttributeError.new(attribute_name:, **error.to_h.slice(:symbol, :message, :context))
                  outcome.add_error(attribute_error)
                end
              end
            end
          end
        end
      end
    end
  end
end
