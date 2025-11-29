RSpec.describe Foobara::Persistence::EntityBase::TransactionTable do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:user_class) do
    stub_class "User", Foobara::Entity do
      attributes id: :integer,
                 first_name: :string
      primary_key :id
    end
  end

  describe "#load_many" do
    context "when already loaded" do
      let!(:user) do
        user_class.transaction do
          user_class.create(first_name: "f")
        end
      end

      it "just returns the already-loaded record" do
        user_class.transaction do
          record = user_class.load(user.id)
          loaded = user_class.load_many(record)

          expect(loaded).to eq([record])
          expect(loaded.first).to be_loaded
        end
      end
    end
  end

  describe "#all" do
    context "when a thunk is unloaded" do
      it "still yields the loaded record for that thunk" do
        user = user_class.transaction do
          user_class.create(first_name: "Basil")
        end

        user_class.transaction do |tx|
          user_class.thunk(user.id)

          transaction_table = tx.table_for(user_class)

          transaction_table.all do |record|
            expect(record).to be_loaded
            expect(record.first_name).to eq("Basil")
          end
        end
      end
    end
  end
end
