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

    # TODO: we seem to have symbol here for error reporting. Can we eliminate it?
    attr_accessor :symbol, :extends

    # Can we eliminate symbol here or no?
    # Has a collection of transformers and validators.
    # transformers return an outcome that might contain a new value
    # validators return error arrays
    # a caster is a special type of transformer expected to happen before all other
    # transformers and validators.
    #
    # let's explore the use-case of attributes processing...
    #
    # 1) validate that it's a hash
    # 2) validate the keys are symbolizeable
    # 3) symbolize the keys
    # 4) fill in default values for missing keys
    # 5) for each key in the schemas keys, process each value against its schema (cast it, transform it, validate it)
    # 5) validate required attributes are present
    # 6) validate there aren't extra keys
    # .
    # Looks like this splits up nicely in to 3 steps... casting, transforming, validating. Unsure if this ordering
    # will always hold so I'm tempted to combine transformers and validators into one collection to be more flexible.
    # Although this means it is doing some of the validation as part of the casting steps.
    #
    # What if we don't allow transformers to fail? Then they have to be split into a validator and transformer.
    # then validators give errors and transformers give a new value to replace the prior value.
    # .
    # OK I'll go that route but I think I have to eliminate any idea of pre-defined order based on type.
    #
    # steps are... change casters into processors.
    # ohhhh maybe we should pass them an outcome?? nah. Well... we could make a base class do that? Let's do that.
    #
    # notes: needed/useful transformers/validators to implement:
    #
    # default (cast from nil at attribute level)
    # required (validation at attributes level)
    # allow_empty (validation at attribute level)
    # allow_nil (validation at attribute level)
    # one_of (validation at attribute level)
    # max_length (string validation at attribute level)
    # max (integer validation at attribute level)
    # matches (string against a regex)
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

    def cast_from(value)
      caster = casters(true).find { |c| c.applicable?(value) }

      if caster
        caster.cast_from(value)
      else
        Outcome.error(
          CannotCastError.new(
            message: "Could not find any applicable casters to cast from #{value} to #{symbol}",
            context: {
              cast_to_type: symbol,
              value:
            }
          )
        )
      end
    end

    def validation_errors(value)
      # TODO: actually return something of interest here!
      []
    end

    register_builtin(:duck)
    register_builtin(:integer)
    register_builtin(:map)
    # TODO: eliminate attributes as a built-in
    register_builtin(:attributes)
  end
end
