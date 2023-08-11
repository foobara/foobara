module Foobara
  module Types
    module Transformers
      module Attributes
        class AddDefaults < Value::Transformer
          class << self
            # TODO: have convention of grabbing this from the class name instead
            def symbol
              :defaults
            end

            def data_schema
              :duck # TODO: fix this when we have a way to specify attributes with unspecified keys
            end
          end

          def defaults
            declaration_data
          end

          def transform(attributes_hash)
            defaults.merge(attributes_hash)
          end
        end
      end
    end
  end
end
