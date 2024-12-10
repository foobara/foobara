RSpec.describe Foobara::CommandConnectors::Serializers::EntitiesToPrimaryKeysSerializer do
  after do
    Foobara.reset_alls
  end

  let(:serializer) { described_class.new(detached_to_primary_key:) }
  let(:object) { detached_entity_class.new(foo: "foo", bar: "bar", id: 100) }
  let(:detached_entity_class) do
    stub_class "SomeDetachedEntity", Foobara::DetachedEntity do
      attributes do
        id :integer, :required
        foo :string, :required
        bar :string, :required
      end
      primary_key :id
    end
  end

  describe "#serialize" do
    context "when detached_to_primary_key is true" do
      let(:detached_to_primary_key) { true }

      it "converts it to its primary key" do
        expect(serializer.serialize(object)).to eq(100)
      end
    end

    context "when detached_to_primary_key is false" do
      let(:detached_to_primary_key) { false }

      it "converts it to its attributes" do
        expect(serializer.serialize(object)).to eq(foo: "foo", bar: "bar", id: 100)
      end
    end
  end
end
