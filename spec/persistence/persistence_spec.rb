RSpec.describe Foobara::Persistence do
  after do
    Foobara.reset_alls
  end

  describe ".current_transaction_table" do
    before do
      described_class.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

      stub_class :User, Foobara::Entity do
        attributes id: :integer
        primary_key :id
      end
    end

    it "returns the transaction table" do
      User.transaction do |tx|
        table = described_class.current_transaction_table(User)
        expect(table).to be_a(Foobara::Persistence::EntityBase::TransactionTable)
        expect(table.transaction).to be(tx)
      end
    end
  end

  describe ".register_base" do
    context "when using a prefix" do
      let(:user_class) do
        stub_class :User, Foobara::Entity do
          attributes id: :integer
          primary_key :id
        end
      end

      let(:driver_class) { Foobara::Persistence::CrudDrivers::InMemory }

      it "registers the base and its crud drivers uses prefixes" do
        expect {
          described_class.register_base(driver_class, name: "some_base", prefix: "some_prefix")
        }.to change(described_class.bases, :size).by(1)

        base = described_class.bases["some_base"]

        expect(base).to be_a(Foobara::Persistence::EntityBase)

        table = base.entity_attributes_crud_driver.table_for(user_class)

        expect(table.table_name).to eq("some_prefix_user")
      end
    end
  end

  describe ".sort_bases" do
    context "with entity classes each with different bases" do
      let(:entity_class1) do
        stub_class("Entity1", Foobara::Entity) do
          attributes do
            id :integer
          end
          primary_key :id
        end
      end
      let(:entity_class2) do
        stub_class("Entity2", Foobara::Entity) do
          attributes do
            id :integer
            entity1 Entity1
          end
          primary_key :id
        end
      end
      let(:entity_class3) do
        stub_class("Entity3", Foobara::Entity) do
          attributes do
            id :integer
            entity2 Entity2
          end
          primary_key :id
        end
      end
      let(:entity_class4) do
        stub_class("Entity4", Foobara::Entity) do
          attributes do
            id :integer
            entity3 Entity3
          end
          primary_key :id
        end
      end

      let(:base1) { entity_class1.entity_base }
      let(:base2) { entity_class2.entity_base }
      let(:base3) { entity_class3.entity_base }
      let(:base4) { entity_class4.entity_base }
      let(:base5) { described_class.register_base(Foobara::Persistence::CrudDrivers::InMemory, name: "Base5") }

      it "can sort the bases as expected" do
        [
          entity_class1,
          entity_class2,
          entity_class3,
          entity_class4
        ].each do |entity_class|
          base = described_class.register_base(
            Foobara::Persistence::CrudDrivers::InMemory,
            name: entity_class.name
          )
          described_class.register_entity(base, entity_class)
        end

        # Without any reason to sort them they will not be sorted so let's create some records
        described_class.transaction(base1, base2, base3, base4) do
          entity_class4.create(
            entity3: entity_class3.create(
              entity2: entity_class2.create(entity1: entity_class1.create)
            )
          )
        end

        expect(
          described_class.sort_bases([base3, base4, base5, base1, base2])
        ).to eq([base4, base3, base2, base1, base5])
      end
    end
  end
end
