module Foobara
  class Type
    class Caster
      class CannotCastError < Error
        def initialize(**opts)
          super(**opts.merge(symbol: :cannot_cast))
        end
      end

      class << self
        def instance
          @instance ||= new(type_symbol: implied_type_symbol)
        end

        def implied_type_symbol
          parent = Util.module_for(self)
          if parent.name == "Casters"
            grandparent = Util.module_for(parent)
            unless grandparent == Type
              grandparent.name.demodulize.underscore.to_sym
            end
          end
        end
      end

      attr_accessor :type_symbol

      def initialize(type_symbol: nil)
        self.type_symbol = type_symbol
      end

      delegate :implied_type_symbol, to: :class
    end
  end
end
