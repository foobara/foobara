module Foobara
  module BuiltinTypes
    # TODO: Rename to StringType to avoid needing to remember ::String elsewhere in the code
    module String
      module SupportedTransformers
        class Downcase < Value::Transformer.subclass(transform: :downcase.to_proc, name: "Downcase")
        end
      end
    end
  end
end
