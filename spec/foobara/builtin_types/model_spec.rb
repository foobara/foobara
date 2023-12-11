RSpec.describe ":model" do
  after do
    Foobara.reset_alls
  end

  let(:type) do
    Foobara::TypeDeclarations::Namespace.type_for_declaration(type_declaration)
  end

  let(:type_declaration) do
    {
      type: :model,
      name: model_name,
      attributes_declaration:
    }
  end
  let(:model_name) { "SomeModel" }
  let(:attributes_declaration) do
    {
      foo: { type: :integer, max: 10 },
      # TODO: aren't we supposed to be doing required: false instead??
      bar: { type: :string, required: true }
    }
  end

  let(:constructed_model) { type.target_class }

  it "creates a type that targets a Model subclass" do
    expect(type).to be_a(Foobara::Types::Type)
    expect(constructed_model.name).to eq("Foobara::Model::SomeModel")

    value = constructed_model.new

    expect(value.model_name).to eq("SomeModel")

    expect(value).to be_a(Foobara::Model)
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
      message: 'At foo: Cannot cast "invalid" to an integer. Expected it to be a Integer, ' \
               "or be a string of digits optionally with a minus sign in front",
      context: { cast_to: { type: :integer, max: 10 }, value: "invalid" }
    )

    value = constructed_model.new(foo: 4, bar: "baz")
    expect(value).to be_valid

    value.write_attribute!(:foo, 5)
    expect(value.foo).to eq(5)

    expect {
      value.write_attribute!(:foo, "asdf")
    }.to raise_error(Foobara::Value::Processor::Casting::CannotCastError)

    value.write_attributes(foo: 6)
    expect(value.foo).to eq(6)

    value.write_attributes!(foo: 7)
    expect(value.foo).to eq(7)

    expect {
      value.write_attributes!(foo: "asdf")
    }.to raise_error(Foobara::Value::Processor::Casting::CannotCastError)
  end

  context "when model has a domain but no organization (ie is in the global organization)" do
    let(:domain) do
      stub_module "SomeOrg" do
        foobara_organization!
      end

      stub_module "SomeOrg::SomeDomain" do
        foobara_domain!
      end.foobara_domain
    end

    let(:type_declaration) do
      {
        type: :model,
        name: model_name,
        attributes_declaration:,
        model_module: domain.full_domain_name
      }
    end

    describe "#full_model_name" do
      subject { type.target_class.full_model_name }

      it { is_expected.to eq("SomeOrg::SomeDomain::#{model_name}") }
    end
  end

  it "sets model_class and model_base_class" do
    expect(type.declaration_data[:model_class]).to eq("Foobara::Model::SomeModel")
    expect(type.declaration_data[:model_base_class]).to eq("Foobara::Model")
  end

  it "extends duck" do
    expect(type.extends_type?(Foobara::Types.global_registry[:duck])).to be(true)
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
          ) { |error| expect(error.path).to eq([:foo]) }
        end
      end
    end
  end

  describe "#possible_errors" do
    it "gives expected possible errors" do
      expect(type.possible_errors).to eq(
        "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
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
      expect(namespace.type_for_declaration(:SomeModel)).to be(type)
    end

    context "when used as attribute type" do
      let(:new_type) do
        namespace.type_for_declaration(
          first_name: :string,
          some_model: :SomeModel
        )
      end
      let(:actual_value) do
        new_type.process_value!(
          first_name: "SomeFirstName",
          some_model: {
            foo: "2",
            bar: :whatever
          }
        )
      end
      let(:expected_value) do
        {
          first_name: "SomeFirstName",
          some_model: constructed_model.new({ foo: 2, bar: "whatever" }, validate: false)
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
          binding.pry
          types_manifest = Foobara.manifest[:organizations][:global_organization][:domains][:global_domain][:types]

          expect(types_manifest[:SomeModel][:declaration_data][:name]).to eq("SomeModel")
        end
      end
    end
  end

  describe "using model_module to specify domain" do
    let(:domain_module) {
      stub_module "SomeDomain" do
        foobara_domain!
      end
    }
    let(:type_declaration) do
      {
        type: :model,
        name: model_name,
        attributes_declaration:,
        model_module:
      }
    end
    let(:model_module) { domain_module }
    let(:type) do
      domain_module.type_for_declaration(type_declaration)
    end

    let(:constructed_model) do
      type.target_class
    end

    it "can be used by symbol" do
      expect(type.name).to eq("SomeModel")
      expect(domain_module.type_for_declaration(:SomeModel)).to be(type)
    end

    it "is registered where expected" do
      expect(type.full_type_name).to eq("SomeDomain::SomeModel")
      expect(constructed_model.domain.domain_name).to eq("SomeDomain")
      expect(constructed_model.domain).to be(domain_module.foobara_domain)
    end

    context "when using domain name instead" do
      let(:model_module) { "SomeDomain" }

      it "still works" do
        expect(type.full_type_name).to eq("SomeDomain::SomeModel")
        expect(constructed_model.domain.domain_name).to eq("SomeDomain")
      end
    end
  end
end
