module Foobara
  module BuiltinTypes
    module Entity
      class Transformers
        # TODO: why doesn't this happen automatically??
        class Mutable < Model::Transformers::Mutable
        end
      end
    end
  end
end
