module Foobara
  module BuiltinTypes
    # TODO: Rename to StringType to avoid needing to remember ::String elsewhere in the code
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
