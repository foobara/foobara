RSpec.describe Foobara::TypeDeclarations::Attributes do
  describe ".reject" do
    let(:type) do
      Foobara::GlobalDomain.foobara_type_from_declaration(foo: :integer)
    end
    let(:type_declaration) { type.declaration_data }

    context "when nothing changes" do
      it "gives back the same hash" do
        expect(described_class.reject(type_declaration, :bar)).to eq(type_declaration)
      end
    end
  end
end
