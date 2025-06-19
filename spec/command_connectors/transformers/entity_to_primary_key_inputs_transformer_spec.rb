RSpec.describe Foobara::CommandConnectors::Transformers::EntityToPrimaryKeyInputsTransformer do
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

  let(:transformer) { described_class.new(to: type) }

  it "gives an expected from_type" do
    expect(transformer.from_type.declaration_data).to eq(
      type: :attributes,
      element_type_declarations: {
        some_tuple: {
          type: :tuple,
          element_type_declarations: [
            { type: :integer },
            { type: :string },
            { type: :integer, description: "SomeEntity id" }
          ],
          size: 3
        },
        some_array: {
          type: :array,
          element_type_declaration: { type: :integer, description: "SomeEntity id : some random entity" }
        },
        some_model: {
          type: :attributes,
          element_type_declarations: {
            some_entity: { type: :integer, description: "SomeEntity id" },
            foo: { type: :string },
            bar: { type: :string }
          }
        }

      }
    )
  end

  context "when type has no associations and isn't an entity" do
    let(:type) { Foobara::BuiltinTypes[:string] }

    it "has a from_type that is the to_type" do
      expect(transformer.from_type).to eq(transformer.to_type)
    end
  end

  describe "#transform" do
    it "gives what was passed in because we expect this data to be cast where needed" do
      expect(transformer.transform(value)).to eq(
        some_tuple: [1, "foo", some_record.id],
        some_array: [some_record.id],
        some_model: { some_entity: some_record.id, foo: "foo", bar: "bar" }
      )
    end
  end
end
