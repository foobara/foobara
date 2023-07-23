Foobara::Util.require_directory("#{__dir__}/type")

module Foobara
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
  #
  # And what does a Schema contain?
  # Just expressions for expressing types?
  # So we ask the schema to give us a type??
  class Type
    class << self
      def build_and_register(symbol:, **args)
        types[symbol] = new(symbol:, **args)
      end

      def register(symbol, type)
        types[symbol] = type
      end

      def register_builtin(symbol)
        build_and_register(symbol:, **BuiltinTypeBuilder.new(symbol).to_args)
      end

      def types
        @types ||= {}
      end

      def [](symbol)
        types[symbol]
      end
    end

    attr_accessor :symbol, :extends

    # Can we eliminate symbol here or no?
    def initialize(symbol:, casters: [], extends: nil)
      self.extends = extends
      @local_casters = Array.wrap(casters)
      self.symbol = symbol
    end

    def casters(inherits = false)
      @casters ||= if !inherits || extends.blank?
                     @local_casters
                   else
                     @local_casters + extends.casters
                   end
    end

    # Do we really need this method?
    def can_cast?(value)
      cast_from(value).success?
    end

    # Do we really need this method?
    def casting_errors(value)
      cast_from(value).errors
    end

    # Do we really need this method?
    def cast_from!(value)
      outcome = cast_from(value)

      if outcome.success?
        outcome.result
      else
        outcome.raise!
      end
    end

    def validation_errors(_value)
      # TODO: override this in relevant base types
      []
    end

    def cast_from(value)
      error_outcomes = casters.map do |caster|
        outcome = caster.cast_from(value)

        return outcome if outcome.success?

        outcome
      end

      Outcome.merge(error_outcomes)
    end

    register_builtin(:duck)
    register_builtin(:integer)
    register_builtin(:map)
    # TODO: eliminate attributes as a built-in
    register_builtin(:attributes)
  end
end
