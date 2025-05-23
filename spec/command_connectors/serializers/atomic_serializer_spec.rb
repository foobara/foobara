RSpec.describe Foobara::CommandConnectors::Serializers::AtomicSerializer do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:serializer) { described_class.new }
  let(:entity_class) do
    stub_class "SomeEntity", Foobara::Entity do
      attributes do
        id :integer
        foo :string, :required
        bar :string, :required
      end
      primary_key :id
    end
  end

  describe "#serialize" do
    let(:record) do
      entity_class.transaction do
        entity_class.create(foo: "foo", bar: "bar")
      end
    end

    context "when serializing an unloaded thunk" do
      it "loads the thunk" do
        record_id = record.id

        entity_class.transaction do
          thunk = entity_class.thunk(record_id)
          expect(thunk).to_not be_loaded

          result = serializer.serialize(thunk)

          expect(thunk).to be_loaded
          expect(result).to eq(foo: "foo", bar: "bar", id: record_id)
        end
      end
    end

    context "when serializing a model containing an entity" do
      let(:model_class) do
        entity_class

        stub_class "SomeModel", Foobara::Model do
          attributes do
            some_entity :SomeEntity, :required
            name :string, :required
          end
        end
      end

      let(:model_instance) do
        model_class.new(some_entity: record, name: "some name")
      end

      it "serializes the entity in an atomic fashion" do
        result = serializer.serialize(model_instance)

        expect(result).to eq(some_entity: { foo: "foo", bar: "bar", id: record.id }, name: "some name")
      end
    end
  end
end
