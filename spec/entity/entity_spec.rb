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
        model_class: "User",
        model_base_class: "Foobara::Entity",
        attributes_declaration: {
          type: :attributes,
          element_type_declarations: {
            id: { type: :integer },
            name: { type: :string }
          }
        },
        primary_key: :id,
        model_module: nil
      }
    end

    it "creates a model class" do
      expect(defined?(User)).to be_falsey
      Foobara::GlobalDomain.foobara_type_from_strict_stringified_declaration(declaration_data)
      expect(defined?(User)).to be_truthy
    end
  end
end
