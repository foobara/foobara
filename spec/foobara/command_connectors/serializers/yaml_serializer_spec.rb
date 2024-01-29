RSpec.describe Foobara::CommandConnectors::Serializers::YamlSerializer do
  let(:serializer) { described_class.new("some request") }
  let(:object) { { foo: "bar" } }

  describe "#serialize" do
    it "serializes the object to yaml" do
      expect(serializer.serialize(object)).to eq("---\n:foo: bar\n")
    end
  end

  describe "#priority" do
    subject { serializer.priority }

    it { is_expected.to be_a(Integer) }
  end
end
