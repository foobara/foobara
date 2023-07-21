require "foobara/error"

module Foobara
  class Model
    class Type
      class Caster
        class CannotCastError < Error
          def initialize(**opts)
            super(**opts.merge(symbol: :cannot_cast))
          end
        end

        def initialize(type_symbol = nil)
          if type_symbol.is_a?(Type)
            @type = type_symbol
          elsif type_symbol.is_a?(Symbol)
            @type_symbol = type_symbol
          end
        end

        def type
          @type ||= unless @type_symbol
                      @type_symbol ||= begin
                        parent = Util.module_for(self.class)

                        if parent.name.demodulize == "Casters"
                          Util.module_for(parent).name.demodulize.underscore.to_sym
                        end
                      end

                      raise "could not infer type symbol" unless @type_symbol

                      Model.type_for(type_symbol)
                    end
        end

        def type_symbol
          @type_symbol || type.symbol
        end

        delegate :symbol, :ruby_class, to: :type

        class << self
          def instance
            @instance ||= new
          end
        end
      end
    end
  end
end
