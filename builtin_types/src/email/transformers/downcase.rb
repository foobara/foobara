module Foobara
  module BuiltinTypes
    module Email
      module Transformers
        # Seems like it might be cleaner to just assemble these parts in one place instead of in different files?
        # Hard to say.
        class Downcase < BuiltinTypes::String::SupportedTransformers::Downcase
          def always_applicable?
            true
          end
        end
      end
    end
  end
end
