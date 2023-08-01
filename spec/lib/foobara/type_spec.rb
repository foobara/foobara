RSpec.describe Foobara::Type do
  let(:type) { described_class[type_symbol] }

  context "when :attributes" do
    let(:type_symbol) { :attributes }

    describe "#cast_from" do
      let(:outcome) { type.process(hash) }
      let(:result) { outcome.result }
      let(:errors) { outcome.errors }

      context "when hash has symbolic keys" do
        let(:hash) { { foo: "bar" } }

        it "is the hash" do
          expect(outcome).to be_success
          expect(result).to be(hash)
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
  end

  describe ".[]" do
    context "when looking up a primitive" do
      it "returns a primitive" do
        expect(described_class[:integer]).to be_a(Foobara::Type::PrimitiveType)
      end
    end
  end
end
