RSpec.describe ":entity" do
  after do
    Foobara.reset_alls
  end

  let(:type) do
    Foobara::TypeDeclarations::Namespace.type_for_declaration(type_declaration)
  end

  let(:type_declaration) do
    {
      type: :entity,
      name: model_name,
      attributes_declaration:,
      primary_key:
    }
  end
  let(:primary_key) { :pk }
  let(:model_name) { "SomeEntity" }
  let(:attributes_declaration) do
    {
      foo: { type: :integer, max: 10 },
      pk: { type: :integer },
      # TODO: aren't we supposed to be doing required: false instead??
      bar: { type: :string, required: true }
    }
  end

  let(:constructed_model) { type.target_classes.first }

  it "creates a type that targets a Model subclass" do
    expect(type).to be_a(Foobara::Types::Type)
    expect(constructed_model.name).to eq("Foobara::Entity::SomeEntity")

    value = constructed_model.new

    expect(value.model_name).to eq("SomeEntity")

    expect(value).to be_a(Foobara::Entity)
    expect(value).to_not be_valid

    value.foo = "10"

    expect(value.foo).to be(10)
    expect(value).to_not be_valid

    value.bar = "baz"

    expect(value).to be_valid
    expect(value.validation_errors).to be_empty

    value.foo = "invalid"

    expect(value).to_not be_valid

    expect(value.validation_errors.size).to eq(1)
    expect(value.validation_errors.first.to_h).to eq(
      key: "data.foo.cannot_cast",
      path: [:foo],
      runtime_path: [],
      category: :data,
      is_fatal: true,
      symbol: :cannot_cast,
      message: "Cannot cast invalid. Expected it to be a Integer, " \
               "or be a string of digits optionally with a minus sign in front",
      context: { cast_to: { type: :integer, max: 10 }, value: "invalid" }
    )

    value = constructed_model.new(foo: 4, bar: "baz")
    expect(value).to be_valid
  end

  it "sets model_class and model_base_class" do
    expect(type.declaration_data[:model_class]).to eq("Foobara::Entity::SomeEntity")
    expect(type.declaration_data[:model_base_class]).to eq("Foobara::Entity")
  end

  describe "constructed model" do
    describe ".new with validate: true" do
      let(:attributes) do
        {
          foo: 10,
          pk: 1,
          bar: "baz"
        }
      end

      let(:record) { constructed_model.new(attributes, validate: true) }

      context "with invalid attributes" do
        let(:attributes) do
          {
            foo: 11,
            pk: 1,
            bar: "baz"
          }
        end

        it "explodes" do
          expect {
            record
          }.to raise_error(
            Foobara::BuiltinTypes::Number::SupportedValidators::Max::MaxExceededError
          ) { |error| expect(error.path).to eq([:foo]) }
        end
      end

      describe "#write_attribute" do
        context "when writing value that makes record invalid" do
          it "is not valid" do
            expect(record).to be_valid

            record.write_attribute(:not_a_real_attribute, :whatever)

            expect(record).to_not be_valid
          end
        end
      end

      describe "#write_attribute!" do
        context "when writing value that makes record invalid" do
          it "explodes" do
            expect(record).to be_valid

            expect {
              record.write_attribute!(:foo, 11)
            }.to raise_error(
              Foobara::BuiltinTypes::Number::SupportedValidators::Max::MaxExceededError
            ) { |error| expect(error.path).to eq([:foo]) }
          end
        end
      end

      describe "#read_attribute!" do
        context "when attribute doesn't exist" do
          it "explodes" do
            expect {
              record.read_attribute!(:no_such_attribute)
            }.to raise_error(Foobara::Model::NoSuchAttributeError)
          end
        end

        context "when attribute exists" do
          it "returns expected value" do
            expect(record.read_attribute!(:foo)).to eq(10)
          end
        end
      end
    end
  end

  context "when primary key doesn't point at a real attribute" do
    let(:primary_key) { :not_a_valid_attribute }

    it "explodes" do
      expect {
        type
      }.to raise_error(
        Foobara::TypeDeclarations::Handlers::ExtendEntityTypeDeclaration::
          ValidatePrimaryKeyReferencesAttribute::InvalidPrimaryKeyError
      )
    end
  end

  context "when primary key isn't a symbol or a string" do
    let(:primary_key) { Object.new }

    it "explodes" do
      expect {
        type
      }.to raise_error(
        Foobara::TypeDeclarations::Handlers::ExtendEntityTypeDeclaration::ValidatePrimaryKeyIsSymbol::
            PrimaryKeyNotSymbolError
      )
    end
  end

  context "when primary key is a string" do
    let(:primary_key) { "foo" }

    it "can still create the type" do
      expect(type.declaration_data[:primary_key]).to eq(:foo)
    end
  end

  context "when primary key is missing" do
    let(:type_declaration) do
      {
        type: :entity,
        name: model_name,
        attributes_declaration:
      }
    end

    it "explodes" do
      expect {
        type
      }.to raise_error(
        Foobara::TypeDeclarations::Handlers::ExtendEntityTypeDeclaration::ValidatePrimaryKeyPresent::
            MissingPrimaryKeyError
      )
    end
  end

  describe "#process_value!" do
    let(:value) { type.process_value!(value_to_process) }

    context "when instantiating via type declaration instead of class" do
      let(:value_to_process) do
        { foo: "10", bar: :baz }
      end

      it "constructs value" do
        expect(value).to be_a(constructed_model)
      end
    end

    context "when instantiating via model instance" do
      let(:value_to_process) do
        constructed_model.new(attributes)
      end

      let(:attributes) do
        { "foo" => 10, "bar" => :baz }
      end

      it "constructs value" do
        expect(value).to be_a(constructed_model)
        expect(value).to be(value_to_process)
        expect(value).to be_valid
      end

      context "when invalid attributes" do
        let(:attributes) do
          { foo: "invalid", bar: :baz }
        end

        it "explodes" do
          expect { value }.to raise_error(
            Foobara::Value::Processor::Casting::CannotCastError,
            /Expected it to be a Integer, or be a string of digits optionally with a minus sign in front\z/
          ) { |error|            expect(error.path).to eq([:foo]) }
        end
      end
    end
  end

  describe "#possible_errors" do
    it "gives expected possible errors" do
      expect(type.possible_errors).to eq(
        "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.pk.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.missing_required_attribute": Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::
            MissingRequiredAttributeError,
        "data.unexpected_attributes": Foobara::BuiltinTypes::Attributes::SupportedProcessors::
            ElementTypeDeclarations::UnexpectedAttributesError,
        "data.bar.missing_required_attribute": Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::
            MissingRequiredAttributeError,
        "data.foo.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.foo.max_exceeded": Foobara::BuiltinTypes::Number::SupportedValidators::Max::MaxExceededError,
        "data.bar.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError
      )
    end
  end

  describe "registering model on a namespace" do
    let(:namespace) do
      Foobara::TypeDeclarations::Namespace.new("model registration test")
    end

    around do |example|
      Foobara::TypeDeclarations::Namespace.using namespace do
        example.run
      end
    end

    before do
      namespace.register_type(type.name, type)
    end

    it "can be used by symbol" do
      expect(namespace.type_for_declaration(:SomeEntity)).to be(type)
    end

    context "when used as attribute type" do
      let(:new_type) do
        namespace.type_for_declaration(
          first_name: :string,
          some_model: :SomeEntity
        )
      end
      let(:actual_value) do
        new_type.process_value!(
          first_name: "SomeFirstName",
          some_model: {
            foo: "2",
            bar: :whatever,
            pk: 500
          }
        )
      end
      let(:expected_value) do
        {
          first_name: "SomeFirstName",
          some_model: constructed_model.new(pk: 500, foo: 3, bar: "whatasdfsever")
        }
      end

      it "can process a value" do
        expect(actual_value).to eq(expected_value)
        expect(actual_value).to_not be(expected_value)
        expect(actual_value.hash).to eq(expected_value.hash)
        expect(actual_value.eql?(expected_value)).to be(true)
      end

      describe "Foobara.manifest" do
        it "contains the type for the model" do
          expect(
            Foobara.manifest[:global_organization][:global_domain][:types][:SomeEntity][:declaration_data][:name]
          ).to eq("SomeEntity")
        end
      end
    end
  end

  describe "using model_module to specify domain" do
    let(:domain_module) {
      Module.new do
        class << self
          def name
            "SomeDomain"
          end

          foobara_domain!
        end
      end
    }
    let(:type_declaration) do
      {
        type: :entity,
        name: model_name,
        attributes_declaration:,
        model_module:,
        primary_key:
      }
    end
    let(:model_module) { domain_module }
    let(:type) do
      domain_module.type_for_declaration(type_declaration)
    end

    let(:constructed_model) do
      type.target_classes.first
    end

    before do
      stub_const(domain_module.name, domain_module)
    end

    it "can be used by symbol" do
      expect(type.name).to eq("SomeEntity")
      expect(domain_module.type_for_declaration(:SomeEntity)).to be(type)
    end

    it "is registered where expected" do
      expect(type.full_type_name).to eq("SomeDomain::SomeEntity")
      expect(constructed_model.domain.domain_name).to eq("SomeDomain")
      expect(constructed_model.domain).to be(domain_module.foobara_domain)
    end

    context "when using domain name instead" do
      let(:model_module) { "SomeDomain" }

      it "still works" do
        expect(type.full_type_name).to eq("SomeDomain::SomeEntity")
        expect(constructed_model.domain.domain_name).to eq("SomeDomain")
      end
    end
  end
end
