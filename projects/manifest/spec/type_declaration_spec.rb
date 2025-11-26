RSpec.describe Foobara::Manifest do
  after do
    Foobara.reset_alls
  end

  let(:model_class) do
    stub_class("SomeModel", Foobara::Model) do
      attributes do
        foo :string
      end
    end
  end

  let(:command_class) do
    stub_class("SomeCommand", Foobara::Command) do
      inputs do
        some_model SomeModel, :allow_nil
      end
    end
  end

  let(:root_manifest) { Foobara::Manifest::RootManifest.new(raw_manifest) }
  let(:raw_manifest) do
    model_class
    command_class
    Foobara.manifest
  end

  describe "#to_model" do
    context "when an allow_nil type declaration of a model" do
      let(:type_declaration) { Foobara::Manifest::TypeDeclaration.new(root_manifest, path) }
      let(:path) { [:command, "SomeCommand", :inputs_type, :element_type_declarations, :some_model] }

      it "can still cast it to a model from a type_declaration" do
        expect(type_declaration.to_model).to be_a(Foobara::Manifest::Model)
      end
    end
  end
end
