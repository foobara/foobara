require "foobara/value/caster"

module Foobara
  module Type
    module Casters
      module Symbol
        class Symbol < Type::Casters::DirectTypeMatch
          include Singleton

          def initialize
            super(type_symbol: :symbol, ruby_classes: ::Symbol)
          end
        end
      end
    end
  end
end
