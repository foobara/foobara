RSpec.describe Foobara::Model do
  after do
    Foobara.reset_alls
    if Object.const_defined?(:User)
      Object.send(:remove_const, :User)
    end
  end

  describe "extending an entity with mutability" do
    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    end

    let(:entity_declaration_data) do
      {
        type: :entity,
        name: "User",
        attributes_declaration: {
          id: { type: :integer },
          name: { type: :string },
          age: { type: :integer }
        },
        primary_key: :id
      }
    end
    let(:extended_entity_declaration_data) do
      { type: :User, mutable: [:age] }
    end
    let(:entity_type) do
      Foobara::Domain.global.foobara_type_from_declaration(entity_declaration_data)
    end
    let(:extended_entity_type) do
      Foobara::Domain.global.foobara_type_from_declaration(extended_entity_declaration_data)
    end

    it "handles an extension properly" do
      expect(entity_type).to be_a(Foobara::Types::Type)

      described_class.deanonymize_class(entity_type.target_class)

      User.transaction do
        user = entity_type.process_value!(name: "Fumiko", age: 100)
        expect(user).to be_a(User)
        expect(user.mutable).to be true

        extended_user = extended_entity_type.process_value!(name: "Barbara", age: 200)
        expect(extended_user).to be_a(User)
        expect(extended_user.mutable).to eq([:age])
      end
    end

    context "when adding attributes to an existing entity" do
      before do
        entity_type.target_class.class_eval do
          attributes do
            email :string, :required
          end
        end
      end

      it "adds the attributes to the existing type" do
        type = Foobara.foobara_lookup_type(:User)
        attributes_type = type.element_types
        expect(attributes_type.element_types.keys).to match_array(%i[id name age email])
      end
    end

    context "when changing an entity's immutability" do
      it "updates the type's mutable processor declaration data" do
        entity_type
        expect {
          entity_type.target_class.mutable [:age]
        }.to change { Foobara.foobara_lookup_type(:User).declaration_data[:mutable] }.from(nil).to([:age])
      end
    end
  end

  describe "extending a model with mutability" do
    let(:model_declaration_data) do
      {
        type: :model,
        name: "User",
        attributes_declaration: {
          name: { type: :string },
          age: { type: :integer }
        }
      }
    end
    let(:extended_model_declaration_data) do
      { type: :User, mutable: [:age] }
    end
    let(:model_type) do
      Foobara::Domain.global.foobara_type_from_declaration(model_declaration_data)
    end
    let(:extended_model_type) do
      Foobara::Domain.global.foobara_type_from_declaration(extended_model_declaration_data)
    end

    it "handles an extension properly" do
      expect(model_type).to be_a(Foobara::Types::Type)
      described_class.deanonymize_class(model_type.target_class)

      user = model_type.process_value!(name: "Fumiko", age: 100)
      expect(user).to be_a(User)
      expect(user.mutable).to be true

      extended_user = extended_model_type.process_value!(name: "Barbara", age: 200)
      expect(extended_user).to be_a(User)
      expect(extended_user.mutable).to eq([:age])
    end

    context "when adding attributes to an existing model" do
      before do
        model_type.target_class.class_eval do
          attributes do
            email :string, :required
          end
        end
      end

      it "adds the attributes to the existing type" do
        type = Foobara.foobara_lookup_type(:User)
        attributes_type = type.element_types
        expect(attributes_type.element_types.keys).to match_array(%i[name age email])
      end
    end

    context "when changing a model's immutability" do
      it "updates the type's mutable processor declaration data" do
        model_type
        expect {
          model_type.target_class.mutable [:age]
        }.to change { Foobara.foobara_lookup_type(:User).declaration_data[:mutable] }.from(nil).to([:age])
      end
    end
  end
end
