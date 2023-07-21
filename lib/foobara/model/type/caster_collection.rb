require "foobara/error"

module Foobara
  class Model
    class Type
      class CasterCollection < Caster
        class CannotCastError < Error
          def initialize(**opts)
            super(**opts.merge(symbol: :cannot_cast))
          end
        end

        attr_accessor :casters

        def initialize(*casters)
          super()
          self.casters = casters
        end

        delegate :symbol, :ruby_class, to: :type

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
end
