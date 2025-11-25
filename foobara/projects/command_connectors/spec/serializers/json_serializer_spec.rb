RSpec.describe Foobara::CommandConnectors::Serializers::JsonSerializer do
  let(:serializer) { described_class.new("some request") }
  let(:object) { { foo: "bar" } }

  describe "#serialize" do
    it "serializes the object to json" do
      expect(serializer.serialize(object)).to eq('{"foo":"bar"}')
    end
  end

  describe "#deserialize" do
    it "deserializes the object from json" do
      expect(serializer.deserialize('{"foo":"bar"}')).to eq("foo" => "bar")
    end
  end

  describe "#priority" do
    subject { serializer.priority }

    it { is_expected.to be_a(Integer) }
  end
end
