require "bigdecimal"

require "foobara/builtin_types/casters/direct_type_match"

module Foobara
  module BuiltinTypes
    module BigDecimal
      module Casters
        # TODO: Should we support NaN, Infinity, -Infinity??
        class BigDecimal < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::BigDecimal)
          end
        end
      end
    end
  end
end
