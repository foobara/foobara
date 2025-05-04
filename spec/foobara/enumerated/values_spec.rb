RSpec.describe Foobara::Enumerated::Values do
  let(:values) do
    described_class.new(enum_declaration)
  end

  context "when module" do
    let(:enum_declaration) do
      Module.new.tap do |m|
        m.const_set(:FOO, :foo)
        m.const_set(:BAR, :bar)
        m.const_set(:BAZ, :baz)
      end
    end

    it "constructs the values" do
      expect(values.all_names).to contain_exactly(:FOO, :BAR, :BAZ)
    end
  end

  context "when hash" do
    let(:enum_declaration) do
      {
        FOO: :foo,
        BAR: :bar,
        BAZ: :baz
      }
    end

    it "constructs the values" do
      expect(values.all_names).to contain_exactly(:FOO, :BAR, :BAZ)
      expect(values.all).to eq(enum_declaration)
    end

    describe "#value?" do
      it "is answers if it is a value" do
        expect(values.value?(:foo)).to be true
        expect(values.value?(:asdf)).to be false
      end
    end
  end

  context "when array" do
    let(:enum_declaration) do
      [
        :FOO,
        :BAR,
        :BAZ
      ]
    end

    it "constructs the values" do
      expect(values.all_names).to contain_exactly(:FOO, :BAR, :BAZ)
      expect(values.all).to eq(enum_declaration.to_h { |key| [key, key] })
    end

    context "when splatted" do
      let(:values) do
        described_class.new(*enum_declaration)
      end

      it "constructs the values" do
        expect(values.all_names).to contain_exactly(:FOO, :BAR, :BAZ)
        expect(values.all).to eq(enum_declaration.to_h { |key| [key, key] })
      end
    end
  end
end
