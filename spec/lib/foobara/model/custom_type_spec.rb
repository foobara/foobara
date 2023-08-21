RSpec.describe "custom types" do
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
