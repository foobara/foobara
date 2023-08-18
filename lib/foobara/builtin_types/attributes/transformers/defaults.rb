module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformer
        class Defaults < Value::Transformer
          class << self
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
