RSpec.describe Foobara::CommandConnector::NotFoundError do
  describe "message" do
    let(:error) { described_class.for("foo") }

    it "mentions the not-found item" do
      expect(error.message).to eq("Not found: foo")
    end

    context "when there's no not-found item provided" do
      let(:error) { described_class.for(nil) }

      it "has a basic not-found message" do
        expect(error.message).to eq("Not found")
      end
    end
  end
end
