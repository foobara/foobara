module Foobara
  class Model
    class TypeBuilder
      module Processors
        module Attribute
          class CastValue < Foobara::Type::ValueProcessor
            attr_accessor :attribute_name, :attribute_type, :path

            def initialize(attribute_name:, attribute_type:, path:)
              super()

              self.path = path
              self.attribute_name = attribute_name
              self.attribute_type = attribute_type
            end

            # can this be split into validators and transformers?
            def process_outcome(outcome)
              attributes_hash = outcome.result

              unless attributes_hash.key?(attribute_name)
                # We will assume that other validators will handle the fact that this is missing
                return outcome
              end

              value = attributes_hash[attribute_name]

              # instead of this let's just grab all the processors from the attribute type in advance so we can build
              # error schemas out of it
              process_outcome = attribute_type.process(value)

              if process_outcome.success?
                outcome.result = attributes_hash.merge(attribute_name => process_outcome.result)
              else
                process_outcome.errors.each do |error|
                  unless error.is_a?(AttributeError)
                    error = AttributeError.new(
                      path:,
                      attribute_name:,
                      **error.to_h.slice(:symbol, :message, :context)
                    )
                  end

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
