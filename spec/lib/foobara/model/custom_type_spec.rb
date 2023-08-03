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
    let(:schema) { Foobara::Model::Schema.for(schema_hash, schema_registries: schema_registry) }

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
      complex_schema.register_validator(:complex, pointless_validator)
      schema_registry.register(complex_schema)
      Foobara::Model::TypeBuilder.builder_registry[:complex] = type_builder
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
