RSpec.describe Foobara::CommandConnectors::Serializer do
  describe ".serializer_from_symbol" do
    it "can find the correct serializer" do
      expect(
        described_class.serializer_from_symbol(:yaml)
      ).to eq(Foobara::CommandConnectors::Serializers::YamlSerializer)
    end
  end
end
