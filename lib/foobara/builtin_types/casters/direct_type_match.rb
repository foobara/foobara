module Foobara
  # Can this live in another project?
  module BuiltinTypes
    module Casters
      class DirectTypeMatch < Value::Caster
        attr_accessor :ruby_classes

        def initialize(*args, ruby_classes:)
          self.ruby_classes = ::Array.wrap(ruby_classes)
          super(*args)
        end

        def applicable?(value)
          ruby_classes.any? { |klass| value.is_a?(klass) }
        end

        def cast(value)
          value
        end

        def applies_message
          ruby_classes.map do |klass|
            "be a #{klass.name}"
          end
        end
      end
    end
  end
end
