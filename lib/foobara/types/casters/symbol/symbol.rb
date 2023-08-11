require "foobara/value/caster"

module Foobara
  module Types
    module Casters
      module Symbol
        class Symbol < Types::Casters::DirectTypeMatch
          include Singleton

          def initialize
            super(type_symbol: :symbol, ruby_classes: ::Symbol)
          end
        end
      end
    end
  end
end
