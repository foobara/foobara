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
      expect(transformer.possible_errors).to eq([])
    end
  end
end
