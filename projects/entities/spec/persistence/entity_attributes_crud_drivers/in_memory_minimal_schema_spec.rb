require "foobara/spec_helpers/it_behaves_like_a_crud_driver"

# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Foobara::Persistence::CrudDrivers::InMemoryMinimal do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = described_class.new
  end

  it_behaves_like_a_crud_driver

  describe "schema manipulation" do
    let(:crud_driver) { described_class.new }
    let(:entity_class) do
      Class.new(Foobara::Persistence::EntityBase) do
        def self.name
          "TestThing"
        end

        attribute :id, :integer
        attribute :name, :string
        attribute :email, :string
      end
    end

    let(:table) { crud_driver.table_for(entity_class) }
    let!(:record1) { table.insert(id: nil, name: "Alice", email: "alice@example.com") }
    let!(:record2) { table.insert(id: nil, name: "Bob", email: "bob@example.com") }

    describe "#rename_attribute" do
      it "renames an attribute across all records" do
        table.rename_attribute(:email, :email_address)

        record1_id = record1[:id]
        record2_id = record2[:id]

        found1 = table.find(record1_id)
        found2 = table.find(record2_id)

        expect(found1).to have_key(:email_address)
        expect(found1).not_to have_key(:email)
        expect(found1[:email_address]).to eq("alice@example.com")

        expect(found2).to have_key(:email_address)
        expect(found2).not_to have_key(:email)
        expect(found2[:email_address]).to eq("bob@example.com")
      end

      it "does nothing if the old attribute does not exist" do
        table.rename_attribute(:nonexistent, :new_name)

        expect(table.attribute_names).to contain_exactly(:id, :name, :email)
      end

      it "works with string attribute names" do
        table.rename_attribute("email", "email_address")

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found).to have_key(:email_address)
        expect(found).not_to have_key(:email)
      end

      it "raises CannotRenameAttributeError when new_name already exists" do
        table.insert(id: nil, name: "Charlie", email: "c@example.com", phone: "555")

        expect {
          table.rename_attribute(:name, :phone)
        }.to raise_error(Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotRenameAttributeError)
      end
    end

    describe "#add_attribute" do
      it "adds a new attribute with nil default to all records" do
        table.add_attribute(:phone)

        record1_id = record1[:id]
        record2_id = record2[:id]

        found1 = table.find(record1_id)
        found2 = table.find(record2_id)

        expect(found1[:phone]).to be_nil
        expect(found2[:phone]).to be_nil
        expect(table.attribute_names).to include(:phone)
      end

      it "does not overwrite existing values" do
        table.add_attribute(:name)

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found[:name]).to eq("Alice")
      end

      it "works with string attribute names" do
        table.add_attribute("phone")

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found).to have_key(:phone)
      end
    end

    describe "#drop_attribute" do
      it "removes an attribute from all records" do
        table.drop_attribute(:email)

        record1_id = record1[:id]
        record2_id = record2[:id]

        found1 = table.find(record1_id)
        found2 = table.find(record2_id)

        expect(found1).not_to have_key(:email)
        expect(found2).not_to have_key(:email)
        expect(table.attribute_names).not_to include(:email)
      end

      it "does nothing if the attribute does not exist" do
        table.drop_attribute(:nonexistent)

        expect(table.attribute_names).to contain_exactly(:id, :name, :email)
      end

      it "works with string attribute names" do
        table.drop_attribute("email")

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found).not_to have_key(:email)
      end
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
