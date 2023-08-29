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
      expect(values.all_names).to match_array(%i[FOO BAR BAZ])
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
      expect(values.all_names).to match_array(%i[FOO BAR BAZ])
      expect(values.all).to eq(enum_declaration)
    end
  end

  context "when array" do
    let(:enum_declaration) do
      %i[
        FOO
        BAR
        BAZ
      ]
    end

    it "constructs the values" do
      expect(values.all_names).to match_array(%i[FOO BAR BAZ])
      expect(values.all).to eq(enum_declaration.to_h { |key| [key, key] })
    end

    context "when splatted" do
      let(:values) do
        described_class.new(*enum_declaration)
      end

      it "constructs the values" do
        expect(values.all_names).to match_array(%i[FOO BAR BAZ])
        expect(values.all).to eq(enum_declaration.to_h { |key| [key, key] })
      end
    end
  end
end
