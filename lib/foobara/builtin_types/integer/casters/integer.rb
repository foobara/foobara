require "foobara/builtin_types/casters/direct_type_match"

module Foobara
  module BuiltinTypes
    module Integer
      module Casters
        class Integer < BuiltinTypes::Casters::DirectTypeMatch
          def initialize
            super(ruby_classes: ::Integer)
          end
        end
      end
    end
  end
end
