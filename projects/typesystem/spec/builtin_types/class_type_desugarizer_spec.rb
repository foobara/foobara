RSpec.describe "ClassTypeDesugarizer" do
  let(:desugarizer) do
    Foobara::BuiltinTypes::Duck::SupportedValidators::InstanceOf::TypeDeclarationExtension::ExtendRegisteredTypeDeclaration::Desugarizers::ClassTypeDesugarizer.new
  end

  context "when rawish_type_declaration is not a hash" do
    it "returns false" do
      # Tests the early return branch when rawish_type_declaration.hash? is false
      # Create a TypeDeclaration where declaration_data is not a Hash
      type_declaration = Foobara::TypeDeclaration.new(:string)
      expect(desugarizer.applicable?(type_declaration)).to be(false)
    end
  end

  context "when using Class as a type" do
    let(:some_class) do
      stub_class("SomeClass")
    end

    let(:type) do
      Foobara::Domain.current.foobara_type_from_declaration(type: some_class, allow_nil: true)
    end

    it "desugarizes to :duck with :instance_of" do
      expect(type.declaration_data).to eq(type: :duck, instance_of: "SomeClass", allow_nil: true)
      expect(type.process_value!(some_class.new)).to be_a(some_class)
      expect(type.process_value!(nil)).to be_nil
    end
  end
end
