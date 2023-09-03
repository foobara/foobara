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
    # type registration end

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
    let(:type) { namespace.type_for_declaration(type_declaration) }

    # TODO: make sure this is tested
    let(:type_declaration_handler) { namespace.type_declaration_handler_for(type_declaration) }
    # type registration start
    let(:type_declaration_handler_class) do
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
            ComplexTypeDeclarationHandler.sugar_for_complex?(value)
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
              name: :complex,
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
            "ComplexTypeDeclarationHandler"
          end

          def sugar_for_complex?(sugary_type_declaration)
            if sugary_type_declaration.is_a?(Symbol)
              sugary_type_declaration = sugary_type_declaration.to_s
            end

            if sugary_type_declaration.is_a?(String)
              @complex_form_regex ||= /\A([a-z])\s*\+\s*(?!\1)([a-z])i\z/

              @complex_form_regex.match?(sugary_type_declaration)
            end
          end
        end

        def applicable?(sugary_type_declaration)
          (sugary_type_declaration.is_a?(Hash) && sugary_type_declaration[:type] == :complex) ||
            sugar_for_complex?(sugary_type_declaration)
        end

        define_method :desugarizers do
          [
            Foobara::TypeDeclarations::Handlers::RegisteredTypeDeclaration::SymbolDesugarizer.instance,
            desugarizer_class.instance
          ]
        end

        delegate :sugar_for_complex?, to: :class
      end
    end

    let(:array_to_complex_caster) do
      klass = complex_class

      Class.new(Foobara::Value::Caster) do
        def applicable?(value)
          value.is_a?(Array) && value.size == 2
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
        self::Error = Class.new(Foobara::Value::DataError) do # rubocop:disable RSpec/LeakyConstantDeclaration
          class << self
            def symbol
              :real_should_not_match_imaginary
            end

            def context
              { foo: :bar }
            end

            def message
              "cant be the same!"
            end

            def context_type_declaration
              { foo: :symbol }
            end
          end
        end

        class << self
          def symbol
            :be_pointless
          end
        end

        def be_pointless
          declaration_data
        end

        def validation_errors(complex)
          # :nocov:
          return unless be_pointless == :true_symbol

          # :nocov:

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
      stub_const("ComplexTypeDeclarationHandler", type_declaration_handler_class)
      namespace.register_type_declaration_handler(type_declaration_handler_class.new)
    end

    context "when type declaration invalid" do
      let(:type_declaration) do
        :"x + yi"
      end

      let(:type_declaration_handler) { type_declaration_handler_class.new }
      let(:type_declaration_validator_class) {
        Class.new(Foobara::TypeDeclarations::TypeDeclarationValidator) do
          self::WhateverError = Class.new(Foobara::Value::DataError) do # rubocop:disable RSpec/LeakyConstantDeclaration
            class << self
              def message
                "whatevs!"
              end

              def context_type_declaration
                { foo: :symbol }
              end
            end
          end

          def validation_errors(_value)
            [build_error]
          end

          def error_context(_value)
            { foo: :bar }
          end
        end
      }

      before do
        validator = type_declaration_validator_class.instance
        ComplexTypeDeclarationHandler.define_method :type_declaration_validators do
          [validator]
        end
      end

      it "cannot get a type from the type declaration handler" do
        outcome = type_declaration_handler.process_value(type_declaration)

        expect(outcome).to_not be_success

        # TODO: why isn't errors an error collection??
        expect(outcome.errors_hash).to eq(
          "data.whatever" => {
            category: :data,
            key: "data.whatever",
            path: [],
            runtime_path: [],
            context: { foo: :bar },
            message: "whatevs!",
            symbol: :whatever
          }
        )
      end
    end

    context "when using the type against valid data from complex type non sugar type declaration" do
      before do
        type.register_supported_processor_class(pointless_validator)
      end

      context "when valid" do
        it "can process the thing" do
          value = in_namespace do
            type.process_value!(n: 5, c: [1, 2])
          end

          complex = value[:c]

          expect(complex).to be_a(complex_class)
          expect(complex.real).to eq(1)
          expect(complex.imaginary).to eq(2)
        end
      end

      context "when invalid" do
        it "can process the thing" do
          outcome = in_namespace { type.process_value(n: 5, c: [2, 2]) }

          expect(outcome).to_not be_success
          errors = outcome.errors

          expect(errors.size).to eq(1)
          error = errors.first
          expect(error.to_h).to eq(
            category: :data,
            key: "data.c.real_should_not_match_imaginary",
            path: [:c],
            runtime_path: [],
            symbol: :real_should_not_match_imaginary,
            context: { foo: :bar },
            message: "cant be the same!"
          )
        end
      end
    end

    context "when using the type against valid data from complex type sugar type declaration" do
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
          value = type.process_value!(n: 5, c: [1, 2])
          complex = value[:c]

          expect(complex).to be_a(complex_class)
          expect(complex.real).to eq(1)
          expect(complex.imaginary).to eq(2)
        end
      end
    end

    context "when registering type" do
      describe "#type_for_declaration" do
        context "when not registered" do
          it "raises" do
            expect {
              namespace.type_for_declaration(:complex)
            }.to raise_error(Foobara::TypeDeclarations::Namespace::NoTypeDeclarationHandlerFoundError)
          end
        end

        context "when registered" do
          let(:type_declaration_handler) { type_declaration_handler_class.new }
          let(:type) { type_declaration_handler.process_value!(type: :complex, be_pointless: :true_symbol) }

          before do
            namespace.register_type(:complex, type)
          end

          it "gives the complex type for the complex symbol" do
            expect(namespace.type_for_declaration(:complex)).to be(type)
          end

          it "can cast if needed" do
            # TODO: this is very confusing.
            # Maybe call this complex type? Too much nested behavior being tested in this test.
            outcome = type.cast([100, 200])

            expect(outcome).to be_success
            value = outcome.result
            expect(value.real).to eq(100)
            expect(value.imaginary).to eq(200)
          end

          it "can give validation_errors if needed" do
            errors = type.validation_errors([-40, -40])
            expect(Foobara::ErrorCollection.to_h(errors)).to eq(
              "data.real_should_not_match_imaginary" => {
                key: "data.real_should_not_match_imaginary",
                path: [],
                runtime_path: [],
                category: :data,
                symbol: :real_should_not_match_imaginary,
                message: "cant be the same!",
                context: { foo: :bar }
              }
            )
          end

          context "with a transformer" do
            let(:transformer_class) do
              Class.new(Foobara::TypeDeclarations::Transformer) do
                def always_applicable?
                  true
                end

                def transform(value)
                  value
                end
              end
            end

            let(:transformer) { transformer_class.instance }

            before do
              type.transformers << transformer
            end

            it "can give validation_errors if needed" do
              errors = type.validation_errors([-40, -40])

              expect(Foobara::ErrorCollection.to_h(errors)).to eq(
                "data.real_should_not_match_imaginary" => {
                  key: "data.real_should_not_match_imaginary",
                  path: [],
                  runtime_path: [],
                  category: :data,
                  symbol: :real_should_not_match_imaginary,
                  message: "cant be the same!",
                  context: { foo: :bar }
                }
              )
            end

            context "when no errors" do
              before do
                type.validators = []
              end

              it "is empty" do
                expect(type.validation_errors([2, -40])).to eq([])
              end
            end
          end
        end
      end
    end
  end
end