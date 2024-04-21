RSpec.describe Foobara::TypeDeclarations do
  describe ".strict" do
    it "puts it in strict mode" do
      expect(described_class.strict?).to be(false)
      described_class.strict do
        expect(described_class.strict?).to be(true)
      end
      expect(described_class.strict?).to be(false)
    end
  end
end
