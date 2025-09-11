RSpec.describe Foobara::CommandConnectors::Transformers::LoadAtomsPreCommitTransformer do
  after { Foobara.reset_alls }

  before do
    crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    Foobara::Persistence.default_crud_driver = crud_driver
  end

  let(:some_entity_class) do
    stub_class "SomeEntity", Foobara::Entity do
      attributes do
        id :integer
        foo :string
        bar :string
      end

      primary_key :id
    end
  end
  let(:some_model_class) do
    some_entity_class

    stub_class "SomeModel", Foobara::Model do
      attributes do
        some_entity SomeEntity
        foo :string
        bar :string
      end
    end
  end

  let(:type) do
    some_model_class

    Foobara::TypeDeclarations::Dsl::Attributes.to_declaration do
      some_tuple [:integer, :string, SomeEntity]
      some_array [{ type: SomeEntity, description: "some random entity" }]
      some_model SomeModel
    end
  end

  let(:value) do
    some_record_id = some_record.id

    some_entity_class.transaction do
      {
        some_tuple: [1, "foo", some_record_id],
        some_array: [some_record_id],
        some_model: { some_entity: some_record_id, foo: "foo", bar: "bar" }
      }
    end
  end
  let(:some_record) do
    some_entity_class.transaction do
      some_entity_class.create(foo: "foo", bar: "bar")
    end
  end
  let(:some_other_record) do
    some_entity_class.transaction do
      some_entity_class.create(foo: "baz", bar: "baz")
    end
  end

  let(:command_class) do
    inputs_type = type
    id = some_other_record.primary_key

    stub_class "SomeCommand", Foobara::Command do
      inputs inputs_type
      result inputs_type

      define_method :execute do
        inputs.merge(some_tuple: [*some_tuple[..-2], id])
      end
    end
  end

  let(:command_connector) do
    Foobara::CommandConnector.new(default_pre_commit_transformers: described_class)
  end

  let(:transformer) { described_class.new(to: type) }

  describe "#transform" do
    it "gives what was passed in because we expect this data to be cast where needed" do
      command_connector.connect(command_class)
      response = command_connector.run(
        full_command_name: command_class.full_command_name,
        inputs: value,
        action: "run"
      )

      expect(response).to be_success

      result = response.outcome.result

      expect(result).to eq(
        some_tuple: [1, "foo", some_other_record],
        some_array: [some_record],
        some_model: SomeModel.new(some_entity: some_record, foo: "foo", bar: "bar")
      )
      expect(result[:some_array].first).to be_loaded
    end
  end
end
