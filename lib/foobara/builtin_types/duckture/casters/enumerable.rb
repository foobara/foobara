require "foobara/value/caster"

module Foobara
  module BuiltinTypes
    module Duckture
      module Casters
        class Enumerable < BuiltinTypes::Casters::DirectTypeMatch
          def initialize(*args)
            super(*args, ruby_classes: ::Enumerable)
          end
        end
      end
    end
  end
end
