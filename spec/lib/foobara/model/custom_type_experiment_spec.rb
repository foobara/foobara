# :nocov:
# rubocop:disable RSpec/ScatteredSetup
# rubocop:disable RSpec/ScatteredLet

RSpec.describe "custom types", skip: "only documentation for now" do
  # We need the following chunks...
  #
  # Schema
  #   .can_handle?(sugary_schema_hash) x
  #   #desugarize
  #   #build_schema_validation_errors
  #   #to_h (is this really needed?)
  #   #type (can/should just inherit this)
  #
  # also, need to register the schema
  #
  # TypeBuilder
  #   #casters
  #   #value_processors
  #   #symbol (can/should just inherit)
  #
  # also, need to register the builder
  #
  # each caster needs:
  #
  # Caster
  #   #applicable?
  #   #cast
  #   #applies_message
  #
  # Each ValueTransformer needs
  #   #transform
  #
  # Each ValueValidator needs
  #   .validator_symbol
  #   .data_schema # this would be better called value_schema I think...
  #   validation_errors
  #   #error_symbol
  #   #error_message
  #   #error_context
  #   Error
  #     .context_schema # should we move this??
  #
  # also, need to call .register_validator for any desired validators on the Schema. Another good reason to couple??
  #
  # finally, need to call Type.register_custom_type or register it in a local registry and pass that registry around
  context "when defining a custom complex type" do
    after do
      Foobara::Model::TypeBuilder.clear_type_cache
    end

    let(:complex_class) do
      Class.new do
        attr_accessor :real, :imaginary
      end
    end

    let(:schema_registry) { Foobara::Model::Schema::Registry.new }
    let(:type) { Foobara::Model::TypeBuilder.type_for(schema) }
    let(:schema) { Foobara::Model::Schema::Registry.global.schema_for(schema_hash, schema_registry:) }

    # type experiment start
    # helpers start
    let(:complex_form_regex) { /\A([a-z])\s*\+\s*(?!\1)([a-z])i\z/ }
    let(:sugar_for_complex) {
      ->(sugary_schema) do
        if sugary_schema.is_a?(Symbol)
          sugary_schema = sugary_schema.to_s
        end

        if sugary_schema.is_a?(String)
          complex_form_regex.match?(sugary_schema)
        end
      end
    }
    # helpers end

    # reg start
    # schema start
    # PROBLEM: can't derive the type symbol from the class name since there is no class
    let(:type_symbol) { :complex }

    # PROBLEM: can't use super here... so harder to write (unless you don't understand the patterns, then easier)
    let(:can_handle) { ->(sugary_schema) { sugary_schema == :complex || sugar_for_complex.call(sugary_schema) } }
    # PROBLEM: again can't use super but could expose a function that could be called instead
    let(:desugarize) {
      ->(sugary_schema) {
        if sugar_for_complex?(raw_schema) || type == :complex
          { type: }
        else
          sugary_schema
        end
      }
    }
    # schema end
    #
    # casters start
    let(:casters) do
      [
        {
          applicable: ->(value) { value.is_a?(Array) && value.size == 2 },
          applies_message: "be an array with two elements",
          cast: ->((real, imaginary)) {
            complex_class.new.tap { |complex|
              complex.real = real
              complex.imaginary = imaginary
            }
          }
        },
        {
          applicable: ->(value) { value.is_a?(complex_class) },
          applies_message: "be a complex",
          cast: ->(value) { value }
        }
      ]
    end
    # casters end
    #
    # type builder start
    # NOTE: nothing to do here really since the casters are now grouped in an array above and that's all
    # the type builder was doing in this case was grouping the casters...
    # type builder end
    #
    # validators start
    let(:validators) do
      [
        {
          symbol: :be_pointless,
          # NOTE: this is the schema for what is passed to the constructor of the validator
          # confusing name
          # TODO: rename
          data_schema: :symbol,
          validation_errors: ->(complex, be_pointless) {
            return unless be_pointless == :true_symbol

            if complex.real == complex.imaginary
              {}
            end
          },
          error: {
            schema: { foo: :symbol },
            symbol: :real_should_not_match_imaginary,
            context: { foo: :bar },
            message: "cant be the same!"
          }
        }
      ]
    end
    # validators end
    #
    # registration calls start
    # BENEFIT: dont have to register the validator/schema/builder separately since they are in the structure already
    before do
      schema_registry.register_type_structure(
        type_symbol,
        schema: {
          can_handle: ->(sugary_schema) { sugary_schema == type_symbol || sugar_for_complex.call(sugary_schema) },
          desugarize: ->(sugary_schema) {
            if sugar_for_complex?(raw_schema) || type == type_symbol
              { type: }
            else
              sugary_schema
            end
          }
        },
        type: {
          casters: [
            {
              applicable: ->(value) { value.is_a?(Array) && value.size == 2 },
              applies_message: "be an array with two elements",
              cast: ->((real, imaginary)) {
                complex_class.new.tap { |complex|
                  complex.real = real
                  complex.imaginary = imaginary
                }
              }
            },
            {
              applicable: ->(value) { value.is_a?(complex_class) },
              applies_message: "be a complex",
              cast: ->(value) { value }
            }
          ],
          # Do transformers occur before or after validators?
          # Before means we can make an invalid casted value valid before the validators run and incorrectly fail.
          # After has the risk that a transformer generates an invalid value and the validators fail to catch it.
          # So before it is?
          transformers: {
            plus: {
              data_schema: :complex,
              transform: ->(complex, complex_to_add) { complex + complex_to_add }
            }
          },
          validators: {
            be_pointless: {
              # NOTE: this is the schema for what is passed to the constructor of the validator
              # confusing name
              # TODO: rename
              data_schema: :symbol,
              validation_errors: ->(complex, be_pointless) {
                return unless be_pointless == :true_symbol

                if complex.real == complex.imaginary
                  {}
                end
              },
              error: {
                schema: { foo: :symbol },
                symbol: :real_should_not_match_imaginary,
                context: { foo: :bar },
                message: "cant be the same!"
              }
            }
          }
        }
      )
    end
    # registration calls end
    #
    # reg end
    # type experiment end

    # type registration start
    let(:complex_schema) do
      Class.new(Foobara::Model::Schema) do
        class << self
          def can_handle?(sugary_schema)
            super || sugar_for_complex?(sugary_schema)
          end

          def sugar_for_complex?(sugary_schema)
            if sugary_schema.is_a?(Symbol)
              sugary_schema = sugary_schema.to_s
            end

            if sugary_schema.is_a?(String)
              @complex_form_regex ||= /\A([a-z])\s*\+\s*(?!\1)([a-z])i\z/

              @complex_form_regex.match?(sugary_schema)
            end
          end

          def name
            "ComplexSchema"
          end
        end

        def desugarize
          if sugar_for_complex?(raw_schema)
            { type: }
          else
            super
          end
        end

        delegate :sugar_for_complex?, to: :class
      end
    end

    let(:array_to_complex_caster) do
      klass = complex_class

      Class.new(Foobara::Type::Caster) do
        def applicable?(value)
          value.is_a?(Array) && value.size == 2
        end

        def applies_message
          "be an array with two elements"
        end

        define_method :cast do |(real, imaginary)|
          complex = klass.new

          complex.real = real
          complex.imaginary = imaginary

          complex
        end
      end
    end

    let(:type_builder) do
      casters = [
        array_to_complex_caster.new,
        Foobara::Type::Casters::DirectTypeMatch.new(type_symbol: :complex, ruby_classes: complex_class)
      ]

      Class.new(Foobara::Model::TypeBuilder) do
        define_method :casters do
          casters
        end
      end
    end

    let(:pointless_validator) do
      Class.new(Foobara::Type::ValueValidator) do
        self::Error = Class.new(Foobara::Type::AttributeError) do # rubocop:disable RSpec/LeakyConstantDeclaration
          class << self
            def error_schema
              {
                foo: :symbol
              }
            end
          end
        end

        class << self
          def symbol
            :be_pointless
          end

          def data_schema
            :symbol # TODO: use boolean instead once we have one
          end
        end

        def be_pointless
          validator_data
        end

        def validation_errors(complex)
          return unless be_pointless == :true_symbol

          if complex.real == complex.imaginary
            build_error
          end
        end

        def error_symbol
          :real_should_not_match_imaginary
        end

        def error_context(_value)
          { foo: :bar }
        end

        def error_message(_value)
          "cant be the same!"
        end
      end
    end

    before do
      complex_schema.register_validator(pointless_validator)
      schema_registry.register(complex_schema)
    end
    # type registration end

    context "when using the type against valid data from complex type non sugar schema" do
      let(:schema_hash) do
        {
          type: :attributes,
          schemas: {
            n: :integer,
            # not entirely complex since we only support integers for the components for now but whatever
            c: { type: :complex, be_pointless: :true_symbol }
          }
        }
      end

      context "when valid" do
        it "can process the thing" do
          value = type.process!(n: 5, c: [1, 2])
          complex = value[:c]

          expect(complex).to be_a(complex_class)
          expect(complex.real).to eq(1)
          expect(complex.imaginary).to eq(2)
        end
      end

      context "when invalid" do
        it "can process the thing" do
          outcome = type.process(n: 5, c: [2, 2])

          expect(outcome).to_not be_success
          expect(outcome.result).to be_nil
          errors = outcome.errors

          expect(errors.size).to eq(1)
          error = errors.first
          expect(error.to_h).to eq(
            symbol: :real_should_not_match_imaginary,
            context: { foo: :bar },
            message: "cant be the same!"
          )
        end
      end
    end

    context "when using the type against valid data from complex type sugar schema" do
      let(:schema_hash) do
        {
          type: :attributes,
          schemas: {
            n: :integer,
            c: :"x + yi"
          }
        }
      end

      context "when valid" do
        it "can process the thing" do
          value = type.process!(n: 5, c: [1, 2])
          complex = value[:c]

          expect(complex).to be_a(complex_class)
          expect(complex.real).to eq(1)
          expect(complex.imaginary).to eq(2)
        end
      end
    end
  end
end
# rubocop:enable RSpec/ScatteredLet
# rubocop:enable RSpec/ScatteredSetup

# Final thoughts...
#
# Schema is a type builder. So should eliminate the TypeBuilder class (or the Schema class)
# If Schema knows about Type, then ideally Type doesn't know about Schema. This is a problem because
# we have an idea of context_schema on validator error classes. We have these so that we can express
# error context schemas to the outside world.
#
# What is a type?
#
# Currently, a type is two things:
# 1) A function that takes a value and returns an Outcome with a fully
#    casted/transformned/validated version of the value, or, a collection of type errors.
# 2) It also houses objects for carrying out the above in an explorable manner.
#
# What is a Schema?
#
# A schema is a convenient way for creating a type and more importantly communicating that type's behavior to the
# outside world in a programmatically digestible way. It can take a sugary schema hash, convert it to a strict hash,
# validate the schema hash, generate/find a type from that schema hash.
#
# What is missing?
#
# Perhaps a way to take a type and return a schema. The opposite of schema giving a type.
# If we had this, then validator errors could return a context type. This could then be converted into a schema where
# needed. Probably only built-in types would define error context types directly in order to decouple from Schema.
#
# TODO:
# 1) See if we can we take a type and convert it into a schema
# 2) If we can, express validator error types as types directly instead of using Schema in order to decouple

# let's take yet another swing at possible definitions
#
# * sugary schema value: schema value meant for human expression.
#   ex: { real: :integer, imaginary: :integer }
# * strict schema value: schema value meant for metaprogramming.
#   ex: { type: :attributes, schemas: { real: { type: :integer, }, imaginary: { type: :integer } } }
# * Schema: runtime encapsulation of schema values with a couple operations:
#   1) identifying whether this is the relevant Schema for a given sugary schema value
#   2) converting from a sugary schema value to a strict schema value
#   3) optional: converting from a strict schema value to a sugary schema value
#   4) providing schema validation errors
#   5) housing list of casters to apply
#   7) housing list of transformers to apply
#   6) housing list of validators to apply
#   8) generating a Type
# * Type: runtime encapsulation of a type
#   1) contains the process method
#     * finds the right caster
#     * casts value
#     * transforms value
#     * validates value
#     * gives process outcome
# * Schema Registry
#   1) can find a schema given a sugary schema value
#   2) can find a schema given a type
# * ValueCaster
#   1) says whether it applies to a given value
#   2) casts that value to a value of the desired type
# * ValueTransformer
#   1) takes a value and transforms it somehow into a different value.
# * ValueValidator
#   1) takes a value and returns a list of validation errors
#   2) tells the symbol of the error it would raise and the context type of the error it would raise
#   3) answers whether or not processing should stop
#   4) specifies the type the validator can receive to initialize it (not the value type but context for the validator)

# Next steps?
# 0) Eliminate TypeBuilder and let Schema know about Type again [done]
# 0) Split up transformers and validators [done]
# 1) Change validator to give error type instead of error schema?
# 2) Make all Type creations occur through Schema. This is so we can map from type to schema easily. [done/dup]
# 3) This means needing to move all the primitive types out of Type and into a different project.
# *) Create a faster way of declaring types such as the pseudocode in this file.
# :nocov:
