RSpec.describe Foobara::CommandConnectors::Serializers::AggregateSerializer do
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
    context "when serializing an unloaded thunk" do
      let(:record) do
        entity_class.transaction do
          entity_class.create(foo: "foo", bar: "bar")
        end
      end

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
  end
end
