RSpec.describe Foobara::TypeDeclaration do
  describe "#delete" do
    let(:declaration_data) do
      {
        type: :attributes,
        element_type_declarations: {
          foo: :integer,
          bar: :integer
        },
        required: [:foo, :bar]
      }
    end

    let(:type_declaration) do
      Foobara::TypeDeclaration.new(declaration_data)
    end

    it "deletes the expected attribute and results in a duped declaration" do
      expect(type_declaration.key?(:required)).to be true
      expect(type_declaration).to_not be_duped

      type_declaration.delete(:required)

      expect(type_declaration.key?(:required)).to be false
      expect(type_declaration).to be_duped
    end
  end
end
