RSpec.describe Foobara::CommandConnectors::Serializers::NoopSerializer do
  let(:serializer) { described_class.new("some request") }
  let(:object) { "asdf" }

  describe "#serialize" do
    it "serializes the object to json" do
      expect(serializer.serialize(object)).to eq(object)
    end
  end

  describe "#deserialize" do
    it "deserializes the object from json" do
      expect(serializer.deserialize(object)).to eq(object)
    end
  end

  describe "#priority" do
    subject { serializer.priority }

    it { is_expected.to be_a(Integer) }
  end
end
