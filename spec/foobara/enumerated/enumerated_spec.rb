RSpec.describe Foobara::Enumerated do
  describe ".make_module" do
    let(:mod) { described_class.make_module(*values) }

    let(:values) do
      %i[
        foo-bar
        bar-baz
      ]
    end

    it "has expected constants" do
      expect(mod::FOO_BAR).to eq(:"foo-bar")
    end

    it "has delegated methods" do
      expect(mod.all_values).to match_array(values)
    end

    context "when passing an array" do
      let(:mod) { described_class.make_module(values) }

      it "has expected constants" do
        expect(mod::FOO_BAR).to eq(:"foo-bar")
      end

      it "has delegated methods" do
        expect(mod.all_values).to match_array(values)
      end
    end
  end
end
