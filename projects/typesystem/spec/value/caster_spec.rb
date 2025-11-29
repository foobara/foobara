RSpec.describe Foobara::Value::Caster do
  let(:caster) { described_class.instance }

  describe ".create" do
    let(:caster) do
      described_class.create(
        cast: ->(_whatever) { 1000 },
        name: "Always1000",
        applies_message: "be anything"
      )
    end

    after do
      described_class.send(:remove_const, :Always1000)
    end

    it "creates caster instance with desired behavior" do
      expect(caster.transform(5)).to eq(1000)
      expect(caster.name).to eq("Foobara::Value::Caster::Always1000")
      expect(caster.applies_message).to eq("be anything")
    end
  end
end
