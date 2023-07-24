require "active_support/core_ext/array/conversions"

Foobara::Util.require_directory("#{__dir__}/type")

# some concepts that are kind of hard to keep straight...
# 1) There's the schema type which describes the structure and how to process that structure of the schema hash.
#    That is unrelated to the type/ directory of this monorepo.
# 2) There is the target Ruby class(es) of a value.
# 3) There is the symbol of a Type which is hard to define. It seems to be a base type from which other types
#    could be composed. But those composed types often need to be anonymous.  This is the most confusing of the
#    types and currently seems to only serve the purpose of being passed through to error contexts.
#    Can we eliminate this symbol from the type instance??
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
      def register(symbol, type)
        types[symbol] = type
      end

      def types
        @types ||= {}
      end

      def [](symbol)
        types[symbol]
      end
    end

    # TODO: we seem to have symbol here for error reporting. Can we eliminate it?
    # TODO: eliminate castors
    attr_accessor :casters, :value_processors

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
    def initialize(casters: [], value_processors: [])
      self.casters = Array.wrap(casters)
      self.value_processors = value_processors
    end

    private

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
      caster = casters.find { |c| c.applicable?(value) }

      if caster
        Outcome.success(caster.cast(value))
      else
        applies_messages = casters.map(&:applies_message).flatten
        applies_message = applies_messages.to_sentence(words_connector: ", ", last_word_connector: ", or ")

        Outcome.error(
          CannotCastError.new(
            message: "Cannot cast #{value}. Expected it to #{applies_message}",
            context: {
              cast_to_type: casters.first.type_symbol,
              value:
            }
          )
        )
      end
    end

    public

    def process(value)
      cast_outcome = cast_from(value)

      return cast_outcome unless cast_outcome.success?

      value = cast_outcome.result

      outcome = Outcome.new

      value_processors.each do |value_processor|
        next unless value_processor.applicable?(value)

        processor_outcome = value_processor.process(value)

        if processor_outcome.success?
          value = processor_outcome.result
        else
          processor_outcome.errors.each do |error|
            outcome.add_error(error)
          end

          break if value_processor.error_halts_processing?
        end
      end

      if outcome.success?
        outcome.result = value
      end

      outcome
    end

    def process!(value)
      outcome = process(value)

      if outcome.success?
        outcome.result
      else
        outcome.raise!
      end
    end

    def validation_errors(_value)
      # TODO: actually return something of interest here! Or delete this.
      []
    end

    register(
      :duck,
      Type.new(
        casters: [
          Type::Casters::DirectTypeMatch.new(type_symbol: :duck, ruby_classes: ::Object)
        ],
        value_processors: []
      )
    )
    register(
      :integer,
      Type.new(
        casters: [
          Type::Casters::DirectTypeMatch.new(type_symbol: :integer, ruby_classes: ::Integer),
          Type::ValueProcessors::Integer::CastFromString.new
        ],
        value_processors: []
      )
    )
    register(
      :attributes,
      Type.new(
        casters: Type::Casters::Attributes::Hash.new(type_symbol: :attributes)
      )
    )
  end
end
