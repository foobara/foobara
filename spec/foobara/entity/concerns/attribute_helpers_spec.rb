RSpec.describe Foobara::Entity::Concerns::AttributeHelpers do
  after do
    Foobara.reset_alls
  end

  before do
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
    it "calls attributes_for_aggregate_update" do
      expect(SomeEntity.foobara_attributes_for_update).to be_a(Hash)
    end
  end

  describe ".attributes_for_create" do
    it "removes the primary key" do
      expect(SomeEntity.foobara_attributes_for_create).to eq(
        defaults: { reviews: [] },
        element_type_declarations: { name: { type: :string },
                                     reviews: { element_type_declaration: { type: :integer },
                                                type: :array } },
        required: [:name],
        type: :attributes
      )
    end
  end

  describe ".attributes_for_find_by" do
    it "excludes required and defaults information" do
      expect(SomeEntity.foobara_attributes_for_find_by).to eq(
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
