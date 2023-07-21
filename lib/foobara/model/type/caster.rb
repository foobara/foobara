module Foobara
  class Model
    class Type
      class Caster
        class CannotCastError < Error
          def initialize(**opts)
            super(**opts.merge(symbol: :cannot_cast))
          end
        end

        class << self
          def instance
            @instance ||= new(type_symbol: implied_type_symbol, ruby_class: implied_ruby_class)
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

          def implied_ruby_class
            if implied_type_symbol
              Object.get(implied_type_symbol.to_s.classify)
            end
          end
        end

        attr_accessor :type_symbol, :ruby_class

        def initialize(type_symbol: nil, ruby_class: nil)
          self.type_symbol = type_symbol
          self.ruby_class = ruby_class
        end
      end
    end
  end
end
