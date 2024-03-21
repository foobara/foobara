RSpec.describe ":entity" do
  after do
    Foobara.reset_alls
  end

  let(:type) do
    Foobara::Domain.current.foobara_type_from_declaration(type_declaration)
  end

  let(:type_declaration) do
    {
      type: :entity,
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
      pk: { type: :integer },
      # TODO: aren't we supposed to be doing required: false instead??
      bar: { type: :string, required: true }
    }
  end

  let(:constructed_model) { type.target_class }

  context "when non-block form of transaction" do
    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    end

    it "creates a type that targets a Model subclass" do
      tx = constructed_model.transaction
      tx.open!

      expect(type).to be_a(Foobara::Types::Type)
      expect(constructed_model.name).to eq("Foobara::Entity::SomeEntity")

      value = tx.create(constructed_model)

      expect(value.model_name).to eq("SomeEntity")

      expect(value).to be_a(Foobara::Entity)
      expect(value).to_not be_valid

      value.write_attributes(foo: "10")

      expect(value.foo).to be(10)
      expect(value).to_not be_valid

      value.bar = "baz"

      expect(value).to be_valid
      expect(value.validation_errors).to be_empty

      tx.commit!
      tx = constructed_model.transaction
      tx.open!

      value = tx.thunk(constructed_model, value.primary_key)
      expect(value.foo).to be(10)

      tx.commit!
      tx = constructed_model.transaction
      tx.open!

      value = tx.load(constructed_model, value.primary_key)
      expect(value.foo).to be(10)

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

      value.hard_delete!

      value = tx.create(constructed_model, foo: 4, bar: "baz")
      expect(value).to be_valid

      tx.rollback!
    end

    context "when persisting invalid records" do
      context "when creating" do
        it "raises" do
          expect {
            constructed_model.transaction do
              constructed_model.create
            end
          }.to raise_error(Foobara::Persistence::InvalidRecordError)
        end
      end

      context "when updating" do
        it "raises" do
          record = constructed_model.transaction do
            constructed_model.create(bar: "baz")
          end

          expect {
            constructed_model.transaction do
              record = constructed_model.load(record.primary_key)
              record.foo = "invalid"
            end
          }.to raise_error(Foobara::Persistence::InvalidRecordError)
        end
      end
    end
  end

  context "with block form of transaction" do
    around do |example|
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

      Foobara::Persistence.default_base.transaction do
        example.run
      end
    end

    it "creates a type that targets a Model subclass" do
      expect(type).to be_a(Foobara::Types::Type)
      expect(constructed_model.name).to eq("Foobara::Entity::SomeEntity")

      value = constructed_model.create

      expect(value.model_name).to eq("SomeEntity")

      expect(value).to be_a(Foobara::Entity)
      expect(value).to_not be_valid

      value.write_attributes(foo: "10")

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

      value.hard_delete!

      value = constructed_model.create(foo: 4, bar: "baz")
      expect(value).to be_valid
    end

    describe "#read_attribute!" do
      let(:record) { constructed_model.create }

      after { record.hard_delete! }

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
      let(:record) { constructed_model.create }

      after { record.hard_delete! }

      it "raises validation errors" do
        expect {
          record.validate!
        }.to raise_error(
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError
        )
      end
    end

    it "sets model_class and model_base_class" do
      expect(type.declaration_data[:model_class]).to eq("Foobara::Entity::SomeEntity")
      expect(type.declaration_data[:model_base_class]).to eq("Foobara::Entity")
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
        context "when constructed from string version of primary key" do
          let(:value_to_process) do
            "10"
          end

          it "constructs value" do
            expect(value).to be_a(constructed_model)
          end
        end

        context "when constructed from attributes hash" do
          let(:value_to_process) do
            { "foo" => 10, "bar" => :baz }
          end

          it "constructs created value" do
            expect(value).to be_a(constructed_model)
            expect(value).to be_created
            expect(value.foo).to eq(10)
            expect(value.bar).to eq("baz")
          end
        end
      end

      context "when instantiating via model instance" do
        let(:value_to_process) do
          constructed_model.create(attributes)
        end

        let(:attributes) do
          { "foo" => 10, "bar" => :baz }
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
        expect(type.target_class).to eq(Foobara::Entity::SomeEntity)
        expect(domain.foobara_lookup_type!(:SomeEntity).target_class).to eq(Foobara::Entity::SomeEntity)
      end

      context "when used as attribute type" do
        let(:new_type) do
          type
          domain.foobara_type_from_declaration(
            first_name: :string,
            some_model: :SomeEntity
          )
        end
        let(:record) { constructed_model.create(pk: 500, foo: 3, bar: "whatasdfsever") }
        let(:actual_value) do
          new_type.process_value!(
            first_name: "SomeFirstName",
            some_model: record.pk
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
          type: :entity,
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
  end

  describe "#to_json" do
    subject { instance.to_json }

    let(:instance) { constructed_model.build(pk: 100, foo: 1, bar: "adf") }

    it { is_expected.to eq("100") }

    context "with no primary key" do
      let(:instance) { constructed_model.build(foo: 1, bar: "adf") }

      it { is_expected_to_raise(Foobara::Entity::CannotConvertRecordWithoutPrimaryKeyToJsonError) }
    end
  end
end
