require "foobara/builtin_types/casters/direct_type_match"

module Foobara
  module BuiltinTypes
    module Datetime
      module Casters
        # TODO: Should we support NaN, Infinity, -Infinity??
        class Datetime < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::Time)
          end
        end
      end
    end
  end
end
