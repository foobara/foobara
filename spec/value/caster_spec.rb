RSpec.describe Foobara::Value::Caster do
  let(:caster) { described_class.instance }

  describe ".create" do
    let(:caster) do
      stub_module "SomeModule"

      described_class.create(
        cast: ->(_whatever) { 1000 },
        name: "SomeModule::Always1000"
      )
    end

    it "creates caster instance with desired behavior" do
      expect(caster.transform(5)).to eq(1000)
      expect(caster.name).to eq("SomeModule::Always1000")
    end
  end
end
