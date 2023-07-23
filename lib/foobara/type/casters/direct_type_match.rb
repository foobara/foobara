require "foobara/type/caster"

module Foobara
  class Type
    module Casters
      class DirectTypeMatch < Caster
        attr_accessor :ruby_class

        def initialize(type_symbol: nil, ruby_class: nil)
          self.type_symbol = type_symbol || implied_type_symbol

          unless self.type_symbol
            unless ruby_class
              raise "Cannot infer type_symbol or ruby_class and so must pass one or both of them in."
            end

            self.type_symbol = ruby_class.name.demodulize.downcase.to_sym
          end

          self.ruby_class = ruby_class || implied_ruby_class

          super(type_symbol: self.type_symbol)
        end

        def cast_from(value)
          if value.is_a?(ruby_class)
            Outcome.success(value)
          else
            Outcome.errors(
              CannotCastError.new(
                message: "#{value} is not a #{ruby_class}",
                context: {
                  cast_to_type: type_symbol,
                  value:
                }
              )
            )
          end
        end

        private

        def implied_ruby_class
          Object.const_get(type_symbol.to_s.classify)
        end
      end
    end
  end
end
