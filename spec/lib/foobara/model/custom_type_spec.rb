RSpec.describe "custom types" do
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
  # Each Value::Transformer needs
  #   #transform
  #
  # Each Value::Validator needs
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
      Foobara::TypeDeclarations::Namespace.namespaces.delete(namespace)
    end

    let(:complex_class) do
      Class.new do
        attr_accessor :real, :imaginary
      end
    end
    let(:type) {
      namespace.type_for_declaration(type_declaration)
    }
    # TODO: make sure this is tested
    let(:type_declaration_handler) { namespace.type_declaration_handler_for(schema_hash) }
    # type registration start
    let(:complex_schema) do
      custom_caster = array_to_complex_caster.new
      klass = complex_class

      c = [
        custom_caster,
        Foobara::BuiltinTypes::Casters::DirectTypeMatch.new(ruby_classes: klass)
      ]

      pointless = pointless_validator

      Class.new(Foobara::TypeDeclarations::TypeDeclarationHandler) do
        desugarizer_class = Class.new(Foobara::TypeDeclarations::Desugarizer) do
          def applicable?(value)
            ComplexSchema.sugar_for_complex?(value)
          end

          def desugarize(_value)
            { type: :complex }
          end
        end

        to_type_transformer_class = Class.new(Foobara::TypeDeclarations::ToTypeTransformer) do
          define_method :transform do |strict_type_declaration|
            be_pointless = strict_type_declaration[:be_pointless]

            validators = be_pointless ? [pointless.new(be_pointless)] : []

            Foobara::Types::Type.new(
              strict_type_declaration,
              casters: c,
              transformers: [],
              validators:,
              element_processors: nil
            )
          end
        end

        const_set(:ToTypeTransformer, to_type_transformer_class)

        class << self
          def name
            "ComplexSchema"
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
        end

        def applicable?(sugary_schema)
          sugary_schema == :complex || (sugary_schema.is_a?(Hash) && sugary_schema[:type] == :complex) ||
            sugar_for_complex?(sugary_schema)
        end

        define_method :desugarizers do
          [desugarizer_class.instance]
        end

        delegate :sugar_for_complex?, to: :class

        define_method :casters do
          c
        end
      end
    end

    let(:array_to_complex_caster) do
      klass = complex_class

      Class.new(Foobara::Value::Caster) do
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

    let(:pointless_validator) do
      Class.new(Foobara::Value::Validator) do
        self::Error = Class.new(Foobara::Value::AttributeError) do # rubocop:disable RSpec/LeakyConstantDeclaration
          class << self
            def error_schema
              {
                foo: :symbol
              }
            end

            def symbol
              :real_should_not_match_imaginary
            end

            def context(_value)
              { foo: :bar }
            end

            def message(_value)
              "cant be the same!"
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
          declaration_data
        end

        def validation_errors(complex)
          return unless be_pointless == :true_symbol

          if complex.real == complex.imaginary
            build_error
          end
        end
      end
    end

    let(:namespace) do
      Foobara::TypeDeclarations::Namespace.new(:custom_type_spec)
    end

    def in_namespace(&)
      Foobara::TypeDeclarations::Namespace.using(namespace.name, &)
    end

    before do
      stub_const("ComplexSchema", complex_schema)
      namespace.register_type_declaration_handler(complex_schema.new)
      # namespace.register_type(:complex, type)
      type.register_supported_processor_class(pointless_validator)
    end

    # type registration end

    context "when using the type against valid data from complex type non sugar schema" do
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            n: :integer,
            # not entirely complex since we only support integers for the components for now but whatever
            c: { type: :complex, be_pointless: :true_symbol }
          }
        }
      end

      context "when valid" do
        it "can process the thing" do
          value = in_namespace do
            type.process!(n: 5, c: [1, 2])
          end

          complex = value[:c]

          expect(complex).to be_a(complex_class)
          expect(complex.real).to eq(1)
          expect(complex.imaginary).to eq(2)
        end
      end

      context "when invalid" do
        it "can process the thing" do
          outcome = in_namespace { type.process(n: 5, c: [2, 2]) }

          expect(outcome).to_not be_success
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
      let(:type_declaration) do
        {
          type: :attributes,
          element_type_declarations: {
            n: :integer,
            c: :"x + yi"
          }
        }
      end

      context "when valid" do
        around do |example|
          in_namespace { example.run }
        end

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

# Problem
# when we do something like:
# {type: :attributes, element_type_declarations: { a: { type: :complex } }
# then we have a bit of an issue because :attributes is not going to find the type :complex.
# This is because it is not registered on the global registry rather in a local one which the attributes thingy
# doesn't have access to.
#
# how to handle this??
#
# We somehow need processors that use type declaration handler registries and type registries to know what rules they
# are currently operating under. Should we do this with thread-local variables? Otherwise it seems we would have to pass
# those in to all .process etc calls which would be super annoying and require a non-trivial design change.
#
# So let's say we have domain A with a registry and domain B with a registry. Domain A knows about B but not the other
# way around.
# So a declaration in A should be allowed to reference stuff in B but a declaration in B should not.
#
# How to pull this off?
#
# Thread local registries variable?]
#
# A has global and B, B has global, global has nothing.
#
# if doing A.type_for(type_declaration) then any other type_for calls
=begin
how to implement this??

there's two concepts...

declaration handlers
types

and each has its own registry

let's say in A::Command we do input_schema(:b => :b, c => :integer, :a => :a)

where :a is a type registered in A's type registry and :b is in B's type registry and :integer is in global registry...

Then this is allowed.

but in B::Command if we did that we will get an error because it shouldn't be able to find :a anywhere.

so what does input schema do??

In A::Command it should ask A for its declaration handler registry.  It calls type_for on it passing the declaration.

the declaration handler registry tries to find a declaration handler for this type.

it should find ExtendAttributesHandler in the global declaration handler registry.

The confusion here is that a type declaration expressed in A should be allowed to access types from A but
ExtendAttributesHandler is defined in global and doesn't know about A.

What I think might be hard is knowing what namespace a declaration was originally defined in and detecting when we
are starting processing of a different declaration in a new namespace independently or if we are starting processing
of the other declaration in service of processing the first. How??

I guess one option is a TypeDeclaration object?  It could contain the namespace it belongs to.

whenever processing something in a new TypeDeclaration that is a sub-component of another,
could copy the namespace info over?

but faster from where at at the moment would be thread-local variables...

so...

foobara_namespace = {
  name: :global,
  declaration_handler_registries: [global_declaration_handler_registry],
  type_registries: [global_type_registry]
}


=end
