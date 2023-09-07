module Foobara
  module Value
    # TODO: do we really need these??  Can't just use a transformer?
    class Caster < Transformer
      class << self
        def subclass(name:, applicable_if:, applies_message:, cast:)
          Class.new(self) do
            define_method :name do
              name
            end

            define_method :applicable? do |value|
              applicable_if.call(value)
            end

            define_method :applies_message do
              applies_message
            end

            define_method :cast do |value|
              cast.call(value)
            end
          end
        end
      end

      def applicable?(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def applies_message(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def transform(value)
        cast(value)
      end

      def cast(_value)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end
    end
  end
end
