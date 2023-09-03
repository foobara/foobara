module Foobara
  module BuiltinTypes
    module Email
      module Casters
        # TODO: would a constant work here??
        class String < BuiltinTypes::String::Casters::String
        end
      end
    end
  end
end
