RSpec.describe Foobara::Entity do
  context "when creating an entity from declaration data" do
    after do
      Foobara.reset_alls

      Object.send(:remove_const, :User) if Object.const_defined?(:User)
    end

    let(:declaration_data) do
      {
        type: :entity,
        name: "User",
        model_class: "Foo::Bar::Baz::User",
        model_base_class: "Foobara::Entity",
        attributes_declaration: {
          type: :attributes,
          element_type_declarations: {
            id: { type: :integer },
            name: { type: :string }
          }
        },
        primary_key: :id,
        model_module: "Foo::Bar::Baz",
        mutable: false
      }
    end

    it "creates a model class" do
      expect(Foobara::GlobalDomain).to_not be_foobara_type_registered("User")
      Foobara::GlobalDomain.foobara_type_from_strict_stringified_declaration(declaration_data)
      expect(Foobara::GlobalDomain.foobara_type_registered?("User")).to be true
    end
  end
end
