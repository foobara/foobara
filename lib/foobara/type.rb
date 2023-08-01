require "active_support/core_ext/array/conversions"
require "singleton"

Foobara::Util.require_directory("#{__dir__}/type")

# notes:
# * A schema hash is a hash representation of a type which comes in a two forms
# ** sugary schema hash. Good for humans expressing types to the machine and possibly each other
# ** strict schema hash. Predictable and formal. Good for processing programmatically to accomplish interesting things.
# * a schema is an object representing what was/can be declared in a schema hash.
# * a "type" is a collection of value casters, value transformers, and value validators. It is used to process values.
#    Does this need a better name? It also has a corresponding ruby class or ruby classes to represent an instance
#    of the type at runtime and give it additional value.
# * a "registered type" is a type with a symbolic name and can be represented by that name instead of repeating the type
# * a "primitive type" is a registered type which has no application-programmer-defined behavior at all and is
#   registered in the global registry automatically.
# * an "attributes type" is an important primitive type representing an associative array where the keys are
#   symbols that give the attribute names and the values are types.
# * a "custom type" is a registered type defined by and registered by the application programmer but does not have
#   business meaning.
# * an "anonymous type" is a user-defined type but is not registered.
# * a "model" is an a custom type that does have business meaning. By convention it has an upper-case name.
# * a "value model" is a model which can have programmer defined equality or by default is equal if all the attributes
#   are equal
# * an "entity" is a "model" which is an attributes type, has a with a primary key attribute, and can be represented by
#   its primary key alone. An instance of an entity is called a "record." These records are read from/written to a
#   "store." Two entities are equal if they have the same primary key.

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
      class CannotRegisterPrimitive < StandardError; end

      def register_primitive_type(symbol)
        if all_primitives_registered?
          raise CannotRegisterPrimitive, "Primitives cannot be registered. Register a custom type instead."
        end

        type = Type.new(casters: casters_for_primitive(symbol))

        global_registry.register(symbol, type)
      end

      def all_primitives_registered!
        @all_primitives_registered = true
      end

      def all_primitives_registered?
        @all_primitives_registered
      end

      delegate :[], to: :global_registry

      private

      def global_registry
        @global_registry ||= Registry.new
      end

      def casters_for_primitive(symbol)
        type_module_name = symbol.to_s.camelize.to_sym

        casters_module = Util.constant_value(self::Casters, type_module_name)
        casters = Util.constant_values(casters_module, Class)

        direct_caster = casters.find { |caster| caster.name.to_sym == type_module_name }

        direct_caster = Array.wrap(direct_caster)

        casters -= direct_caster

        [*direct_caster, *casters].compact.map(&:instance)
      end
    end

    # TODO: eliminate castors (or not?)
    # TODO: eliminate children_types by using classes?
    attr_accessor :casters, :value_processors, :children_types

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
    # 2) validate the keys are symbolizable
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
    def initialize(casters: [], value_processors: [], children_types: nil)
      self.children_types = children_types
      self.casters = Array.wrap(casters)
      self.value_processors = value_processors
    end

    def value_validators
      value_processors.select { |processor| processor.is_a?(ValueValidator) }
    end

    def process(value, path = [])
      cast_outcome = cast_from(value)

      return cast_outcome unless cast_outcome.success?

      outcome = OutcomeWithResultEvenIfNotSuccess.new
      outcome.result = cast_outcome.result

      value_processors.each do |value_processor|
        next unless value_processor.applicable?(outcome.result)

        return outcome if value_processor.halt_if_already_not_success? && !outcome.success?

        value_processor.process_outcome(outcome, path)

        return outcome if value_processor.error_halts_processing? && !outcome.success?
      end

      if children_types.is_a?(Hash)
        value = outcome.result

        value.each_key do |attribute_name|
          attribute_type = children_types[attribute_name]
          attribute_outcome = attribute_type.process(value[attribute_name], [*path, attribute_name])

          if attribute_outcome.success?
            value[attribute_name] = attribute_outcome.result
          else
            attribute_outcome.errors.each do |error|
              if error.is_a?(CannotCastError)
                error_hash = error.to_h.except(:type) # why do we have type here? TODO: fix
                error_hash[:context][:attribute_name] = attribute_name

                # Do we really need this translation?? #TODO eliminate somehow
                # TODO: figure out how to eliminate this .compact, perhaps by putting path on the validator
                error = AttributeError.new(path: [*path, attribute_name].compact, **error_hash)
              end

              outcome.add_error(error)
            end
          end
        end
      elsif children_types.is_a?(Array) # TODO: we probably need classes if we want to support arrays and tuples
        if children_types.size != 1
          raise "not sure how to handle more than one element type for an array"
        end

        child_type = children_types.first

        value.each.with_index do |child, index|
          child_outcome = child_type.process(child)

          if child_outcome.success?
            value[index] = child_outcome.result
          else
            child_outcome.errors.each do |error|
              error.path = [path, index, *error.path]
              outcome.add_error(error)
            end
          end
        end
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

    private

    def cast_from(value)
      caster = casters.find { |c| c.applicable?(value) }

      if caster
        Outcome.success(caster.cast(value))
      else
        applies_messages = casters.map(&:applies_message).flatten
        connector = ", or "
        applies_message = applies_messages.to_sentence(
          words_connector: ", ",
          last_word_connector: connector,
          two_words_connector: connector
        )

        Outcome.error(
          CannotCastError.new(
            message: "Cannot cast #{value}. Expected it to #{applies_message}",
            context: {
              cast_to: casters.first.type_symbol,
              value:
            }
          )
        )
      end
    end

    register_primitive_type(:duck)
    register_primitive_type(:symbol)
    register_primitive_type(:integer)
    register_primitive_type(:attributes)
    all_primitives_registered!
  end
end
