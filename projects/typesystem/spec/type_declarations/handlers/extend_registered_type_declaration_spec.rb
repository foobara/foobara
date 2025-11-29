RSpec.describe Foobara::TypeDeclarations::Handlers::ExtendRegisteredTypeDeclaration do
  let(:handler) { described_class.instance }

  describe "#applicable?" do
    subject { handler.applicable?(Foobara::TypeDeclaration.new(type_declaration)) }

    context "when passed what looks like a registered type declaration" do
      let(:type_declaration) { { type: :some_random_type } }

      it { is_expected.to be(false) }
    end
  end
end
