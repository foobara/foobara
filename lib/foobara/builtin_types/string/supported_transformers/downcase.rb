module Foobara
  module BuiltinTypes
    module String
      module SupportedTransformers
        class Downcase < Value::Transformer
          def transform(string)
            string.downcase
          end
        end
      end
    end
  end
end
