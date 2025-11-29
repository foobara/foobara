RSpec.describe Foobara::Types do
  after { Foobara.reset_alls }

  describe "#foobara_manifest" do
    context "when type is registered" do
      before do
        Foobara::GlobalDomain.foobara_register_type(:some_type, type)
      end

      context "when type is sensitive" do
        let(:type) do
          Foobara::GlobalDomain.foobara_type_from_declaration(:string, :sensitive)
        end

        it "includes a sensitive flag" do
          expect(type).to be_sensitive
          expect(type.foobara_manifest[:sensitive]).to be true
          # TODO: come up with a better name for sensitive_exposed and/or sensitive
          expect(type.foobara_manifest.key?(:sensitive_exposed)).to be false
        end
      end

      context "when it is sensitive_exposed" do
        let(:type) do
          Foobara::GlobalDomain.foobara_type_from_declaration(:string, :sensitive_exposed)
        end

        it "includes a sensitive_exposed flag" do
          expect(type).to be_sensitive_exposed
          expect(type.foobara_manifest.key?(:sensitive)).to be false
          expect(type.foobara_manifest[:sensitive_exposed]).to be true
        end
      end
    end
  end
end
