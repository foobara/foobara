RSpec.describe Foobara::CommandRegistry do
  let(:registry) { described_class.new }

  describe "#size" do
    it "returns the number of commands" do
      expect(registry.size).to eq(0)
    end
  end
end
