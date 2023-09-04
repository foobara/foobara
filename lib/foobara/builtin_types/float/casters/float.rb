module Foobara
  module BuiltinTypes
    module Float
      module Casters
        # TODO: Should we support NaN, Infinity, -Infinity??
        class Float < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::Float)
          end
        end
      end
    end
  end
end
