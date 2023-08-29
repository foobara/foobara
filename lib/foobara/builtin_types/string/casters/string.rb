module Foobara
  module BuiltinTypes
    module String
      module Casters
        class String < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::String)
          end
        end
      end
    end
  end
end
