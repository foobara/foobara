module Foobara
  module BuiltinTypes
    module Attributes
      module SupportedTransformers
        class Defaults < Value::Transformer
          def transform(attributes_hash)
            defaults.merge(attributes_hash)
          end
        end
      end
    end
  end
end
