RSpec.describe Foobara::Entity do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    stub_class "InnerMostEntity", described_class do
      attributes do
        id :integer
        name :string, :required
        password :string, :required, :sensitive
      end
      primary_key :id
    end
    stub_class "InnerEntity", described_class do
      attributes do
        id :integer
        name :string, :required
        password :string, :required, :sensitive
        inner_most_entity InnerMostEntity, :sensitive
        inner_most_entities [InnerMostEntity], default: []
      end
      primary_key :id
    end
    stub_class "OuterMostEntity", described_class do
      attributes do
        id :integer
        name :string, :required
        password :string, :required, :sensitive
        inner_entities1 [InnerEntity], :sensitive, default: []
        inner_entities2 [InnerEntity], default: []
      end
      primary_key :id
      # TODO: test using an invalid path! Should blow up upon declaring the delegated
      # attribute not upon accessing it!
      delegate_attribute :inner_name, [:inner_entities1, :"0", :inner_most_entity, :name]
    end
  end

  describe ".construct_deep_associations" do
    it "gives a mapping of data path to type" do
      associations = Foobara::DetachedEntity.construct_deep_associations(OuterMostEntity.model_type)

      expect(associations.keys).to contain_exactly(
        "inner_entities1.#",
        "inner_entities1.#.inner_most_entities.#",
        "inner_entities1.#.inner_most_entity",
        "inner_entities2.#",
        "inner_entities2.#.inner_most_entities.#",
        "inner_entities2.#.inner_most_entity"
      )
    end
  end

  describe ".model_type.type_at_path" do
    it "returns the expected type" do
      expect(
        OuterMostEntity.model_type.type_at_path("inner_entities2.#.inner_most_entities.#.name")
      ).to eq(Foobara::BuiltinTypes[:string])
    end
  end

  describe ".construct_associations" do
    it "gives a mapping of data path to type" do
      associations = Foobara::DetachedEntity.construct_associations(OuterMostEntity.model_type)

      expect(associations.keys).to contain_exactly(
        "inner_entities1.#",
        "inner_entities2.#"
      )
    end
  end
end
