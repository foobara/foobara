require "foobara/value/caster"

module Foobara
  module BuiltinTypes
    module Duck
      module Casters
        class Object < BuiltinTypes::Casters::DirectTypeMatch
          def initialize
            super(type_symbol: :duck, ruby_classes: ::Object)
          end
        end
      end
    end
  end
end
