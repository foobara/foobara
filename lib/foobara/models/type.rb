module Foobara
  module Models
    class Type
      class << self
        def symbol
          name.demodulize.underscore.gsub(/_type$/, "").to_sym
        end

        def schema_validation_errors_for(strict_schema)
        end

        def casting_errors(object)
          unless can_cast?(object)
            Error.new(
              :"cannot_cast_to_#{symbol}",
              "Could not cast #{object.inspect} to #{symbol}",
              cast_to: symbol,
              value: object.inspect
            )
          end
        end
      end
    end
  end
end
