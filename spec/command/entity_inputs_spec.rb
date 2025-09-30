RSpec.describe "Entity inputs for commands" do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    stub_class :User, Foobara::Entity do
      attributes id: :integer,
                 name: { type: :string, required: true },
                 fan_count: { type: :integer, default: 0, max: 10 }
      primary_key :id
    end

    stub_class(:Fan, Foobara::Entity) do
      attributes id: :integer,
                 owner: User,
                 is_active: { type: :boolean, default: true },
                 fan_of: { type: :array, element_type_declaration: User, default: [] },
                 attrs: {
                   foo: { type: :symbol, required: true },
                   bar: [:integer],
                   duckfoo: :duck,
                   duckbar: [:duck]
                 }
      primary_key :id
    end

    stub_class :CreateUser, Foobara::Command do
      inputs User.attributes_type
      result User

      def execute
        create_user

        user
      end

      attr_accessor :user

      def create_user
        self.user = User.create(inputs)
      end
    end

    stub_class :CreateFan, Foobara::Command do
      inputs_type_declaration = Foobara::Util.deep_dup(Fan.attributes_type.declaration_data)
      element_type_declarations = inputs_type_declaration[:element_type_declarations]
      element_type_declarations[:fan_of][:element_type_declaration] = { type: :User, mutable: ["fan_count"] }
      element_type_declarations[:owner] = { mutable: false, type: element_type_declarations[:owner] }

      inputs inputs_type_declaration
      result Fan

      def execute
        create_fan
        increment_fan_count

        fan
      end

      attr_accessor :fan

      def create_fan
        self.fan = Fan.create(inputs)
      end

      def increment_fan_count
        fan.fan_of.each do |user|
          user.fan_count += 1
        end
      end
    end
  end

  # TODO: move this to a test for the ExtendRegisteredModelTypeDeclaration handler
  context "when creating with bad mutable value" do
    it "raises an error" do
      expect {
        CreateFan.domain.foobara_type_from_declaration(
          type: User,
          mutable: :bad_attribute_name
        )
      }.to raise_error(
        Foobara::TypeDeclarations::Handlers::ExtendRegisteredModelTypeDeclaration::MutableValidator::
            InvalidMutableValueGivenError
      )
    end
  end

  context "when an entity doesn't exist" do
    it "gives a not_found error" do
      outcome = CreateFan.run(attrs: { foo: :bar }, fan_of: [10], owner: 10)

      expect(outcome).to_not be_success
      expect(outcome.errors_hash.keys).to contain_exactly("data.fan_of.0.not_found", "data.owner.not_found")
    end
  end

  describe ".possible_errors" do
    it "does not include creation errors for nested entities" do
      User.transaction do
        user1 = CreateUser.run!(name: "Some User1")
        user2 = CreateUser.run!(name: "Some User2")

        CreateFan.run!(attrs: { foo: :bar }, fan_of: [user1])
        CreateFan.run!(attrs: { foo: :baz }, fan_of: [user1, user2])
        CreateFan.run!(attrs: { foo: :foo })

        expect(user1.fan_count).to eq(2)
        expect(user2.fan_count).to eq(1)
      end

      expect(CreateUser.possible_errors.to_h { |p| [p.key.to_sym, p.error_class] }).to eq(
        "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.missing_required_attribute":
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError,
        "data.unexpected_attributes":
          Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
        "data.name.missing_required_attribute":
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError,
        "data.id.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.name.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.fan_count.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.fan_count.max_exceeded": Foobara::BuiltinTypes::Number::SupportedValidators::Max::MaxExceededError
      )

      expect(CreateFan.possible_errors.to_h { |p| [p.key.to_sym, p.error_class] }).to eq(
        "data.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.unexpected_attributes":
          Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
        "data.id.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.is_active.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.owner.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.fan_of.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.fan_of.#.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.fan_of.#.fan_count.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.fan_of.#.fan_count.max_exceeded":
          Foobara::BuiltinTypes::Number::SupportedValidators::Max::MaxExceededError,
        "data.attrs.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.attrs.missing_required_attribute":
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError,
        "data.attrs.unexpected_attributes":
          Foobara::BuiltinTypes::Attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError,
        "data.attrs.foo.missing_required_attribute":
          Foobara::BuiltinTypes::Attributes::SupportedValidators::Required::MissingRequiredAttributeError,
        "data.attrs.foo.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.attrs.bar.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.attrs.bar.#.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.attrs.duckfoo.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.attrs.duckbar.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.attrs.duckbar.#.cannot_cast": Foobara::Value::Processor::Casting::CannotCastError,
        "data.fan_of.#.not_found": Foobara::CommandPatternImplementation::Concerns::Runtime::NotFoundError,
        "data.owner.not_found": Foobara::CommandPatternImplementation::Concerns::Runtime::NotFoundError
      )
    end
  end
end
