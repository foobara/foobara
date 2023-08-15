require "foobara/value/caster"

module Foobara
  module BuiltinTypes
    module Symbol
      module Casters
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
