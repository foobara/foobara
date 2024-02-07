RSpec.describe Foobara::Command::EntityHelpers do
  describe ".type_declaration_for_find_by" do
    let(:entity_class) do
      stub_class("SomeEntity", Foobara::Entity) do
        attributes do
          id :integer
          name :string, :required
          reviews [:integer], default: []
        end
        primary_key :id
      end
    end

    it "excludes required and defaults information" do
      expect(described_class.type_declaration_for_find_by(entity_class)).to eq(
        type: :attributes,
        element_type_declarations: {
          id: { type: :integer },
          name: { type: :string },
          reviews: { type: :array, element_type_declaration: { type: :integer } }
        }
      )
    end
  end
end
