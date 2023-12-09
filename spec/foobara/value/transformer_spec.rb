RSpec.describe Foobara::Value::Transformer do
  let(:transformer) { described_class.instance }

  describe ".create" do
    let(:transformer) do
      stub_module "SomeModule"

      described_class.create(
        transform: ->(_whatever) { 1000 },
        name: "SomeModule::Always1000",
        priority: 40
      )
    end

    it "creates transformer instance with desired behavior" do
      expect(transformer.transform(5)).to eq(1000)
      expect(transformer.name).to eq("SomeModule::Always1000")
      expect(transformer.priority).to eq(40)
    end
  end

  describe "#possible_errors" do
    it "is always empty" do
      expect(transformer.possible_errors).to eq({})
    end
  end

  describe "#process" do
    context "when not applicable" do
      let(:transformer_class) do
        stub_class :SomeTransformer, described_class do
          def applicable?(_value)
            false
          end
        end
      end

      let(:transformer) { transformer_class.instance }

      it "just gives back what was passed in" do
        expect(transformer.process_value(15).result).to eq(15)
      end
    end
  end
end
