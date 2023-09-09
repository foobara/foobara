RSpec.describe Foobara::Value::Caster do
  let(:caster) { described_class.new }

  describe ".create" do
    let(:caster) do
      described_class.create(
        cast: ->(_whatever) { 1000 },
        name: "Always1000"
      )
    end

    it "creates caster instance with desired behavior" do
      expect(caster.transform(5)).to eq(1000)
      expect(caster.name).to eq("Always1000")
    end
  end
end
