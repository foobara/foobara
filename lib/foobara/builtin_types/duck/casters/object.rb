require "foobara/value/caster"

module Foobara
  module Types
    module Casters
      module Duck
        class Object < Types::Casters::DirectTypeMatch
          include Singleton

          def initialize
            super(type_symbol: :duck, ruby_classes: ::Object)
          end
        end
      end
    end
  end
end
