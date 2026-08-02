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

    describe "#column_names" do
      it "returns the column names of the table" do
        expect(table.column_names).to contain_exactly(:id, :name, :email)
      end

      it "returns union of all record keys when records have diverged columns" do
        table.records[1][:phone] = "555-1234"
        table.records[2][:address] = "123 Main St"

        expect(table.column_names).to contain_exactly(:id, :name, :email, :phone, :address)
      end
    end

    describe "#rename_column" do
      it "renames a column across all records" do
        table.rename_column(:email, :email_address)

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

      it "does nothing if the old column does not exist" do
        table.rename_column(:nonexistent, :new_name)

        expect(table.column_names).to contain_exactly(:id, :name, :email)
      end

      it "works with string column names" do
        table.rename_column("email", "email_address")

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found).to have_key(:email_address)
        expect(found).not_to have_key(:email)
      end

      it "raises CannotRenameColumnError when new_name already exists" do
        table.insert(id: nil, name: "Charlie", email: "c@example.com", phone: "555")

        expect {
          table.rename_column(:name, :phone)
        }.to raise_error(Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotRenameColumnError)
      end
    end

    describe "#add_column" do
      it "adds a new column with nil default to all records" do
        table.add_column(:phone)

        record1_id = record1[:id]
        record2_id = record2[:id]

        found1 = table.find(record1_id)
        found2 = table.find(record2_id)

        expect(found1[:phone]).to be_nil
        expect(found2[:phone]).to be_nil
        expect(table.column_names).to include(:phone)
      end

      it "does not overwrite existing values" do
        table.add_column(:name)

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found[:name]).to eq("Alice")
      end

      it "works with string column names" do
        table.add_column("phone")

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found).to have_key(:phone)
      end
    end

    describe "#drop_column" do
      it "removes a column from all records" do
        table.drop_column(:email)

        record1_id = record1[:id]
        record2_id = record2[:id]

        found1 = table.find(record1_id)
        found2 = table.find(record2_id)

        expect(found1).not_to have_key(:email)
        expect(found2).not_to have_key(:email)
        expect(table.column_names).not_to include(:email)
      end

      it "does nothing if the column does not exist" do
        table.drop_column(:nonexistent)

        expect(table.column_names).to contain_exactly(:id, :name, :email)
      end

      it "works with string column names" do
        table.drop_column("email")

        record1_id = record1[:id]
        found = table.find(record1_id)

        expect(found).not_to have_key(:email)
      end
    end
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
