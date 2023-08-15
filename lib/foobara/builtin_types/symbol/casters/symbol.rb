require "foobara/value/caster"

module Foobara
  module BuiltinTypes
    module Symbol
      module Casters
        class Symbol < BuiltinTypes::Casters::DirectTypeMatch
          def initialize
            super(ruby_classes: ::Symbol)
          end
        end
      end
    end
  end
end
