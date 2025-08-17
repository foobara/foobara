RSpec.describe Foobara::Types do
  let(:type) { Foobara::Domain.current.foobara_type_from_declaration(type_declaration) }

  context "when created from scratch" do
    let(:type) do
      Foobara::Types::Type.new(
        "whatever",
        base_type: nil,
        target_classes: [Object]
      )
    end

    it "has no scoped path set" do
      expect(type).to_not be_scoped_path_set
    end
  end

  context "when :attributes" do
    let(:type_declaration) { { foo: :duck } }

    describe "#cast_from" do
      let(:outcome) { type.process_value(hash) }
      let(:result) { outcome.result }
      let(:errors) { outcome.errors }

      context "when hash has symbolic keys" do
        let(:hash) { { foo: "bar" } }

        it "is the hash" do
          expect(outcome).to be_success
          expect(result).to eq(hash)
        end
      end

      context "when hash has symbolizable keys" do
        let(:hash) { { "foo" => "bar" } }

        it "is the hash with symbolized keys" do
          expect(outcome).to be_success
          expect(result).to eq(foo: "bar")
        end
      end

      context "when hash has non-symbolizable keys" do
        let(:hash) { { 10 => "bar" } }

        it "is the hash" do
          expect(outcome).to_not be_success
          expect(errors.first.symbol).to eq(:cannot_cast)
        end
      end
    end

    describe "#extends_directly?" do
      context "when a symbol" do
        it "is true for its parent symbol" do
          expect(type.extends_directly?(:attributes)).to be(true)
        end
      end
    end
  end

  describe "#primitive?" do
    subject { type.primitive? }

    let(:type) { Foobara::Domain.current.foobara_type_from_declaration(type_declaration) }

    context "when primitive" do
      let(:type_declaration) { :integer }

      it { is_expected.to be true }
    end

    context "when derived" do
      let(:type_declaration) do
        { type: :integer, description: "an integer!" }
      end

      it { is_expected.to be false }
    end
  end

  describe "#derived?" do
    subject { type.derived? }

    let(:type) { Foobara::Domain.current.foobara_type_from_declaration(type_declaration) }

    context "when primitive" do
      let(:type_declaration) { :integer }

      it { is_expected.to be false }
    end

    context "when derived" do
      let(:type_declaration) do
        { type: :integer, description: "an integer!" }
      end

      it { is_expected.to be true }
    end
  end
end
