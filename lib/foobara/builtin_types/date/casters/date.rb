require "date"

require "foobara/builtin_types/casters/direct_type_match"

module Foobara
  module BuiltinTypes
    module Date
      module Casters
        # TODO: Should we support NaN, Infinity, -Infinity??
        class Date < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::Date)
          end
        end
      end
    end
  end
end
