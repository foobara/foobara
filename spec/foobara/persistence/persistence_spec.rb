RSpec.describe Foobara::Persistence do
  describe ".current_transaction_table" do
    before do
      described_class.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

      stub_class = ->(klass) { stub_const(klass.name, klass) }

      Class.new(Foobara::Entity) do
        class << self
          def name
            "User"
          end
        end

        stub_class.call(self)

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
end
