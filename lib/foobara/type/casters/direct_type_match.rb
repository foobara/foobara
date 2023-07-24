require "foobara/type/caster"

module Foobara
  class Type
    module Casters
      class DirectTypeMatch < Caster
        attr_accessor :ruby_classes

        def initialize(ruby_classes)
          super()
          self.ruby_classes = Array.wrap(ruby_classes)
        end

        def applicable?(value)
          ruby_classes.any? { |klass| value.is_a?(klass) }
        end

        def cast(value)
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
