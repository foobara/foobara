RSpec.describe Foobara::Types do
  let(:type) { Foobara::TypeDeclarations::Namespace.type_for_declaration(type_declaration) }

  context "when :attributes" do
    let(:type_declaration) { { foo: :duck } }

    describe "#cast_from" do
      let(:outcome) { type.process(hash) }
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
  end
end
