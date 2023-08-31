RSpec.describe Foobara::Value::Transformer do
  let(:transformer) { described_class.new }

  describe "#possible_errors" do
    it "is always empty" do
      expect(transformer.possible_errors).to eq({})
    end
  end

  describe "#process" do
    context "when not applicable" do
      let(:transformer_class) do
        Class.new(described_class) do
          def applicable?(_value)
            false
          end
        end
      end

      let(:transformer) { transformer_class.new }

      it "just gives back what was passed in" do
        expect(transformer.process(15).result).to eq(15)
      end
    end
  end
end
