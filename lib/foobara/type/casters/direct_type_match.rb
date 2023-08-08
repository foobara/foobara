module Foobara
  class Type
    module Casters
      class DirectTypeMatch < Value::Caster
        attr_accessor :ruby_classes, :type_symbol

        def initialize(type_symbol:, ruby_classes:)
          super()
          self.type_symbol = type_symbol
          self.ruby_classes = Array.wrap(ruby_classes)
        end

        def applicable?(value)
          ruby_classes.any? { |klass| value.is_a?(klass) }
        end

        def call(value)
          value
        end

        def applies_message
          ruby_classes.map do |klass|
            "be a ::#{klass.name}"
          end
        end
      end
    end
  end
end
