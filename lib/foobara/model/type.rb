module Foobara
  class Model
    # A type contains the following key information about a "type"
    # * The Ruby class associated with this type which is the class of a value of this type
    # * The casters that can transform values of other types to a value of this type
    # * The validators that can optionally be applied to a value of this type
    # * The transformers that can optionally be applied to a value of this type
    # * unclear if needed, but mandatory validators and transformers
    #
    # how to handle attributes type??
    # Seems like it would require a custom caster/validator?
    # So it seems like an attributes type would be an instance of a type. So we can't use singletons like this
    # and need to go back to non-singletons. Primitives would have singletons. But Attributes can't.
    # They need to be initialized from outside using objects build from Schema objects.
    class Type
      def symbol
        self.class.name.demodulize.underscore.to_sym
      end

      def casting_errors(object)
        unless can_cast?(object)
          Error.new(
            symbol: :cannot_cast,
            message: "Could not cast #{object.inspect} to #{symbol}",
            context: {
              cast_to: symbol,
              value: object
            }
          )
        end
      end

      def validation_errors(_object)
        # TODO: override this in relevant base types
        []
      end
    end
  end
end
