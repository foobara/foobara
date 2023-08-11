require "foobara/value/caster"

module Foobara
  module Types
    module Casters
      module Integer
        class Integer < Type::Casters::DirectTypeMatch
          include Singleton

          def initialize
            super(type_symbol: :integer, ruby_classes: ::Integer)
          end
        end
      end
    end
  end
end
