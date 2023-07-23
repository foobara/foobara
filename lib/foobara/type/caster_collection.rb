module Foobara
  class Type
    class CasterCollection < Caster
      class CannotCastError < Error
        def initialize(**opts)
          super(**opts.merge(symbol: :cannot_cast))
        end
      end

      attr_accessor :casters

      def initialize(*casters)
        if casters.size == 1 && casters.first.is_a?(Array)
          casters = casters.first

        end

        super()

        self.casters = casters
      end

      delegate :symbol, to: :type

      def type
        @type ||= begin
          types = casters.map(&:type).uniq

          if types.size > 1
            raise "There shouldn't be casters for different types in the same collection"
          end

          types.first
        end
      end

      def cast_from(value)
        error_outcomes = casters.map do |caster|
          outcome = caster.cast_from(value)

          return outcome if outcome.success?

          outcome
        end

        Outcome.merge(error_outcomes)
      end
    end
  end
end
