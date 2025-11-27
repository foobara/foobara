RSpec.describe Foobara::NestedTransactionable do
  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  after { Foobara.reset_alls }

  let(:entity_class) do
    stub_class("SomeEntity", Foobara::Entity) do
      attributes do
        id :integer
        foo :string, :required
      end
      primary_key :id
    end
  end

  let(:type) do
    Foobara::Domain.current.foobara_type_from_declaration(SomeEntity)
  end

  describe ".with_needed_transactions_for_type" do
    it "opens needed transactions for the given type" do
      entity_class

      expect {
        described_class.with_needed_transactions_for_type(type) do
          SomeEntity.create(foo: "foo")
        end
      }.to change {
        SomeEntity.transaction { SomeEntity.count }
      }
    end

    context "when type doesn't depend on any entity classes" do
      let(:type) { Foobara::BuiltinTypes[:integer] }

      it "returns the result of the block without opening transactions" do
        expect(described_class.with_needed_transactions_for_type(type) { 100 }).to eq(100)
      end
    end

    context "when there's an error" do
      let(:some_error_class) do
        stub_class("SomeError", StandardError)
      end

      it "rolls back the transaction" do
        entity_class

        expect {
          begin
            described_class.with_needed_transactions_for_type(type) do
              SomeEntity.create(foo: "foo")
              expect(SomeEntity.count).to eq(1)
              raise some_error_class
            end
          rescue SomeError
            nil
          end
        }.to_not change {
          SomeEntity.transaction { SomeEntity.count }
        }
      end
    end
  end
end
