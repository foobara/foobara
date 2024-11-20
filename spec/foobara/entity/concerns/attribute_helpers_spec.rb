RSpec.describe Foobara::Command::EntityHelpers do
  after do
    Foobara.reset_alls
  end

  let(:entity_class) do
    stub_class("SomeEntity", Foobara::Entity) do
      attributes do
        id :integer, :required, default: 10
        name :string, :required
        reviews [:integer], default: []
      end
      primary_key :id
    end
  end

  describe ".attributes_for_update" do
    it "calls type_declaration_for_record_aggregate_update" do
      expect(described_class.attributes_for_update(entity_class)).to be_a(Hash)
    end
  end

  describe ".attributes_for_create" do
    it "removes the primary key and its defaults/required status" do
      expect(described_class.attributes_for_create(entity_class)).to eq(
        defaults: { reviews: [] },
        element_type_declarations: { name: { type: :string },
                                     reviews: { element_type_declaration: { type: :integer },
                                                type: :array } },
        required: [:name],
        type: :attributes
      )
    end
  end

  describe ".type_declaration_for_find_by" do
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
