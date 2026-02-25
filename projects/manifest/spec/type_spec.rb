RSpec.describe Foobara::Manifest::Type do
  after { Foobara.reset_alls }

  context "when it's an associative array" do
    before do
      Foobara::GlobalDomain.foobara_register_type(:some_type,
                                                  type: :associative_array,
                                                  value_type_declaration: :string,
                                                  key_type_declaration: :integer)
    end

    describe "#associative_array?" do
      it "is true" do
        root_manifest = Foobara::Manifest::RootManifest.new(Foobara.manifest)
        expect(root_manifest.type_by_name(:some_type)).to be_associative_array
      end
    end

    describe "#to_type_declaration_from_declaration_data" do
      it "gives an associative_array declaration" do
        root_manifest = Foobara::Manifest::RootManifest.new(Foobara.manifest)
        type = root_manifest.type_by_name(:some_type)
        declaration = type.to_type_declaration_from_declaration_data

        expect(declaration).to be_a(Foobara::Manifest::TypeDeclaration)
        expect(declaration).to be_associative_array
      end
    end
  end
end
