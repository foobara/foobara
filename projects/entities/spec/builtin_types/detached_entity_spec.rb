RSpec.describe ":detached_entity" do
  after do
    Foobara.reset_alls
    [
      :SomeModel,
      :SomeEntity,
      :SomeOrg,
      :SomeDomain
    ].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end

  let(:type) do
    Foobara::Domain.current.foobara_type_from_declaration(type_declaration)
  end

  let(:type_declaration) do
    {
      type: :detached_entity,
      name: model_name,
      attributes_declaration:,
      primary_key:,
      mutable:
    }
  end
  let(:mutable) { false }
  let(:primary_key) { :pk }
  let(:model_name) { "SomeEntity" }
  let(:attributes_declaration) do
    {
      foo: { type: :integer, max: 10 },
      pk: { type: :integer, required: true },
      # TODO: aren't we supposed to be doing required: false instead??
      bar: { type: :string, required: true }
    }
  end

  let(:constructed_model) { type.target_class }

  describe "#read_attribute!" do
    let(:record) { constructed_model.new }

    context "when bad attribute" do
      it "explodes" do
        expect {
          record.read_attribute!("asdfasdf")
        }.to raise_error(Foobara::Model::NoSuchAttributeError)
      end
    end

    context "when good attribute" do
      it "doesn't explode" do
        expect(record.read_attribute!("foo")).to be_nil
      end
    end
  end

  describe "#validate!" do
    let(:record) { constructed_model.new(pk: 1) }

    it "raises validation errors" do
      expect {
        record.validate!
      }.to raise_error(
        Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError
      )
    end
  end

  it "sets model_class and model_base_class" do
    expect(type.declaration_data[:model_class]).to eq("SomeEntity")
    expect(type.declaration_data[:model_base_class]).to eq("Foobara::DetachedEntity")
  end

  describe ".foobara_manifest" do
    it "handles superclass without foobara_manifest" do
      # Tests the else branch when superclass.respond_to?(:foobara_manifest) is false (line 35 in reflection.rb)
      # Create a class that doesn't have foobara_manifest
      base_class = Class.new do
        def self.respond_to?(method)
          method == :foobara_manifest ? false : super
        end
      end
      subclass = Class.new(base_class) do
        include Foobara::DetachedEntity::Concerns::Reflection

        def self.foobara_model_name
          "TestEntity"
        end

        def self.foobara_associations
          {}
        end

        def self.foobara_deep_associations
          {}
        end

        def self.foobara_depends_on
          []
        end

        def self.foobara_deep_depends_on
          []
        end

        def self.foobara_attributes_type
          Foobara::Domain.current.foobara_type_from_declaration(type: :attributes, element_type_declarations: {})
        end

        def self.foobara_primary_key_attribute
          :id
        end
      end
      manifest = subclass.foobara_manifest
      expect(manifest).to be_a(Hash)
      expect(manifest[:entity_name]).to eq("TestEntity")
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
        type: :detached_entity,
        name: model_name,
        attributes_declaration:,
        mutable: true
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
      context "when constructed from attributes hash" do
        let(:value_to_process) do
          { "foo" => 10, "bar" => :baz, pk: 100 }
        end

        it "constructs detached value" do
          expect(value).to be_a(constructed_model)
          expect(value.foo).to eq(10)
          expect(value.bar).to eq("baz")
        end
      end
    end

    context "when instantiating via model instance" do
      let(:value_to_process) do
        constructed_model.new(attributes)
      end

      let(:attributes) do
        { "foo" => 10, "bar" => :baz, pk: 100 }
      end

      it "constructs value" do
        expect(value).to be_a(constructed_model)
        expect(value).to be(value_to_process)
        expect(value).to be_valid
      end
    end
  end

  describe "#possible_errors" do
    let(:mutable) { true }

    it "gives expected possible errors" do
      expect(type.possible_errors.to_h { |p| [p.key.to_sym, p.error_class] }).to eq(
        "data.bar.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.bar.missing_required_attribute":
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError,
        "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.foo.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.foo.max_exceeded": Foobara::BuiltinTypes::Number::SupportedValidators::Max::MaxExceededError,
        "data.missing_required_attribute":
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError,
        "data.pk.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.pk.missing_required_attribute":
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError,
        "data.unexpected_attributes":
          Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError
      )
    end
  end

  describe "registering model on a domain" do
    let(:domain) do
      Foobara::GlobalDomain
    end

    around do |example|
      Foobara::Namespace.use domain do
        example.run
      end
    end

    it "can be used by symbol" do
      Foobara::Model.deanonymize_class(type.target_class)
      expect(type.target_class).to eq(SomeEntity)
      expect(domain.foobara_lookup_type!(:SomeEntity).target_class).to eq(SomeEntity)
    end

    context "when used as attribute type" do
      let(:new_type) do
        type
        domain.foobara_type_from_declaration(
          first_name: :string,
          some_model: :SomeEntity
        )
      end
      let(:record) { constructed_model.new(pk: 500, foo: 3, bar: "whatasdfsever") }
      let(:actual_value) do
        new_type.process_value!(
          first_name: "SomeFirstName",
          some_model: record
        )
      end
      let(:expected_value) do
        {
          first_name: "SomeFirstName",
          some_model: record
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
          type
          expect(Foobara.manifest[:type][:SomeEntity][:declaration_data][:name]).to eq("SomeEntity")
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
        type: :detached_entity,
        name: model_name,
        attributes_declaration:,
        model_module:,
        primary_key:
      }
    end
    let(:model_module) { domain_module }
    let(:type) do
      domain_module.foobara_type_from_declaration(type_declaration)
    end

    let(:constructed_model) do
      type.target_class
    end

    it "can be used by symbol" do
      expect(type.name).to eq("SomeEntity")
      expect(domain_module.foobara_type_from_declaration(:SomeEntity)).to be(type)
      expect(constructed_model.domain.foobara_type_registered?("SomeEntity")).to be(true)
    end

    it "is registered where expected" do
      expect(type.full_type_name).to eq("SomeDomain::SomeEntity")
      expect(constructed_model.domain.foobara_domain_name).to eq("SomeDomain")
      expect(constructed_model.domain).to be(domain_module)
    end

    context "when using domain name instead" do
      let(:model_module) { "SomeDomain" }

      it "still works" do
        expect(type.full_type_name).to eq("SomeDomain::SomeEntity")
        expect(constructed_model.domain.foobara_domain_name).to eq("SomeDomain")
      end
    end
  end

  describe "#to_json" do
    subject { instance.to_json }

    let(:instance) { constructed_model.new(pk: 100, foo: 1, bar: "adf") }

    it { is_expected.to eq("100") }

    context "with no primary key" do
      let(:instance) { constructed_model.new(foo: 1, bar: "adf") }

      it { is_expected_to_raise(Foobara::Entity::CannotConvertRecordWithoutPrimaryKeyToJsonError) }
    end
  end
end
