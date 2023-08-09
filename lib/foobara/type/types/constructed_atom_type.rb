# moar notes...
#
# So far we have 4 types, :duck, :integer, :symbol, :attributes
# and 4 schema types... :duck, :integer, :symbol, :attributes
# and 2 type builders... :attributes and :integer
#
# The other two will have type builders once they have supported validators of some sort.
#
# They match. Having them not-coupled will likely lead to annoyances but coupling them could result in some code-debt
# creeping in over time.
# Probably need to couple them.
# What project should this go into? How do we structure this?
# So far, Schema.for takes a schema hash. TypeBuilder.for takes a schema and returns a type. The type takes a value
# and returns a value.
# What's a use case that makes me want to couple these? Let's say I want to create a new type and call it "complex"
# and use it as a complex number. It could extend the attributes type, have a strict schema of
# { type: :complex, real: :integer, imaginary: :integer }. To accomplish this at the moment, I would have to register a
# schema, register a type builder, and register a type. Maybe that's OK? That might be OK if that call all be abstracted
# away somehow on some kind of Domain.register_model method. But I need to be able to inject the schemas into Schema
# so it can interpret custom types. This might require access to the types, too. Unclear. But if so that would be
# annoying to have the schema and not the type. Also, we're already having schemas creep into the Type project which
# is a backwards dependency at the moment. This is to support context schemas on built-in validator errors.  This is
# solvable but inconvenient.
#
# Oh, another point of confusion, schemas/types/type_builders can be distinguished with symbols and these symbols are
# all the same but it can sometimes be confusing which were dealing with. Error also has a different symbol which can
# get confusing though technically unrelated.
#
# Turns out Schema doesn't currently need type. Maybe just proceed decoupled and see how things shake out.
# Let' make a test that tries to register the above complex type and use it. This would help enumerate all the various
# chunks of implementation required to fully implement a new type.

# notes:
# * A "schema hash" is a hash representation of a type which comes in a two forms
# ** sugary schema hash. Good for humans expressing types to the machine and possibly each other
# ** strict schema hash. Predictable and formal. Good for processing programmatically to accomplish interesting things.
# * a "schema" is an object representing what was/can be declared in a schema hash.
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
  class Type < Value::Processor
    module Types
      class ConstructedAtomType < Type
        class Halt < StandardError
          attr_accessor :errors

          def initialize(errors)
            super("halt")
            self.errors = errors
          end
        end

        attr_accessor :casters, :value_transformers, :value_validators

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
        # 5) for each key in the schemas keys, process each value against its schema
        #    (cast it, transform it, validate it)
        # 5) validate required attributes are present
        # 6) validate there aren't extra keys
        # .
        # Looks like this splits up nicely in to 3 steps... casting, transforming, validating. Unsure if this ordering
        # will always hold so I'm tempted to combine transformers and validators into one collection to be more flexible
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
        def initialize(casters: [], value_transformers: [], value_validators: [], **opts)
          super(**opts)

          self.casters = Array.wrap(casters)
          self.value_transformers = value_transformers
          self.value_validators = value_validators
        end

        def process(value, path = [])
          outcome = cast_from(value)

          return outcome unless outcome.success?

          [*value_transformers, *value_validators].each do |processor|
            new_outcome = processor.process(outcome.result, path)

            unless new_outcome.success?
              new_outcome.each_error do |error|
                # TODO: why do we fix the path here when we pass it in to process?? Should only do one or the other
                error.path = [*path, *error.path]
              end
            end

            outcome.each_error do |error|
              new_outcome.add_error(error)
            end

            outcome = new_outcome

            break if outcome.is_a?(Value::HaltedOutcome)
          end

          outcome
        end

        def cast_from(value)
          caster = casters.find { |c| c.applicable?(value) }

          if caster
            caster.process(value)
          else
            applies_messages = casters.map(&:applies_message).flatten
            connector = ", or "
            applies_message = applies_messages.to_sentence(
              words_connector: ", ",
              last_word_connector: connector,
              two_words_connector: connector
            )

            Value::HaltedOutcome.error(
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
      end
    end
  end
end
