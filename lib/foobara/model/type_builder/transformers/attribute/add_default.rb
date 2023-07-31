module Foobara
  class Model
    class TypeBuilder
      module Transformers
        module Attribute
          class AddDefault < Foobara::Type::ValueTransformer
            attr_accessor :attribute_name, :default_value

            def initialize(attribute_name:, default_value:)
              super()
              self.attribute_name = attribute_name
              self.default_value = default_value
            end

            def transform(attributes_hash)
              if attributes_hash.key?(attribute_name)
                attributes_hash
              else
                attributes_hash.merge(attribute_name => default_value)
              end
            end
          end
        end
      end
    end
  end
end
