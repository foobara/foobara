require "foobara/value/caster"

module Foobara
  module BuiltinTypes
    module Integer
      module Casters
        class Integer < Types::Casters::DirectTypeMatch
          include Singleton

          def initialize
            super(type_symbol: :integer, ruby_classes: ::Integer)
          end
        end
      end
    end
  end
end
