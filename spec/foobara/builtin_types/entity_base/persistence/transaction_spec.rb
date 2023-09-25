RSpec.describe Foobara::Persistence::EntityBase::Transaction do
  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  after do
    Foobara.reset_alls
  end

  let(:entity_class) do
    stub_class = ->(klass) { stub_const(klass.name, klass) }

    Class.new(Foobara::Entity) do
      class << self
        def name
          "SomeEntity"
        end
      end

      stub_class.call(self)

      attributes pk: :integer,
                 foo: :integer,
                 bar: :symbol

      primary_key :pk
    end
  end

  describe ".transaction" do
    it "can create, load, and update records" do
      expect {
        entity_class.create(foo: 1, bar: :baz)
      }.to raise_error(Foobara::Persistence::EntityBase::Transaction::NoCurrentTransactionError)

      transaction = nil

      entity1 = entity_class.transaction do |tx|
        transaction = tx

        entity = entity_class.create(foo: 1, bar: :baz)

        expect(entity).to be_a(entity_class)
        expect(entity).to_not be_persisted
        expect(entity).to_not be_loaded

        expect(tx).to be_open
        expect(Foobara::Persistence.current_transaction(entity)).to be(tx)

        entity
      end

      expect(transaction).to be_closed
      expect(Foobara::Persistence.current_transaction(entity1)).to be_nil

      expect(entity1).to be_a(entity_class)
      expect(entity1).to be_persisted
      expect(entity1).to be_loaded

      entity_class.transaction do
        entity = entity_class.thunk(entity1.primary_key)

        expect(entity).to be_a(entity_class)
        expect(entity).to be_persisted
        expect(entity).to_not be_loaded

        expect(entity.bar).to eq(:baz)

        expect(entity).to be_loaded

        singleton = entity_class.thunk(entity.primary_key)
        expect(singleton).to be(entity)

        entity.bar = "bazbaz"
      end

      entity_class.transaction do
        entity = Foobara::Persistence.current_transaction(entity_class).load(entity_class, entity1.primary_key)
        expect(entity.bar).to eq(:bazbaz)

        expect(entity_class.all.to_a).to eq([entity1])
      end
    end

    it "can rollback" do
      entity1 = entity_class.transaction do
        entity_class.create(foo: 10, bar: :baz)
      end

      entity_class.transaction do |tx|
        entity = entity_class.thunk(entity1.primary_key)
        expect(entity.foo).to eq(10)

        entity.foo = 20

        expect(entity.foo).to eq(20)

        begin
          tx.rollback!
        rescue Foobara::Persistence::EntityBase::Transaction::RolledBack # rubocop:disable Lint/SuppressedException
        end

        expect(entity.foo).to eq(10)

        expect {
          entity.foo = 20
        }.to raise_error(Foobara::Persistence::EntityBase::Transaction::NoCurrentTransactionError)
      end

      entity_class.transaction do |tx|
        entity = entity_class.load(entity1.primary_key)
        entity = entity_class.load(entity.primary_key)
        expect(entity.foo).to eq(10)

        entity.foo = 20

        expect(entity.foo).to eq(20)

        tx.flush!

        expect(entity.foo).to eq(20)

        entity.foo = 30

        tx.revert!

        expect(entity.foo).to eq(20)
      end

      entity_class.transaction do
        entity = entity_class.load(entity1.primary_key)
        expect(entity.foo).to eq(20)
      end
    end

    it "can hard delete" do
      entity_class.transaction do
        expect(entity_class.all.to_a).to be_empty
        entity = entity_class.create(foo: 10, bar: :baz)
        expect(entity_class.all.to_a).to eq([entity])
        entity.hard_delete!
        expect(entity_class.all.to_a).to be_empty
      end

      entity1 = entity_class.transaction do
        expect(entity_class.all.to_a).to be_empty
        entity_class.create(foo: 10, bar: :baz)
      end

      entity_class.transaction do
        entity = entity_class.thunk(entity1.primary_key)
        expect(entity.foo).to eq(10)

        entity.hard_delete!

        expect(entity).to be_hard_deleted

        # TODO: make this work without needing to call #to_a
        expect(entity_class.all.to_a).to be_empty

        expect {
          entity.foo = 20
        }.to raise_error(Foobara::Entity::CannotUpdateHardDeletedRecordError)

        expect(entity.foo).to eq(10)

        entity.restore!

        entity.foo = 20
      end

      entity_class.transaction do
        # TODO: make calling #to_a not necessary
        expect(entity_class.all.to_a).to eq([entity1])
        entity = entity_class.thunk(entity1.primary_key)

        expect(entity).to be_persisted
        expect(entity).to_not be_hard_deleted
        expect(entity.foo).to eq(20)

        entity.hard_delete!

        expect(entity_class.all.to_a).to be_empty
        expect(entity).to be_hard_deleted
      end

      entity_class.transaction do
        expect {
          entity_class.load(entity1.primary_key)
          # TODO: come up with a more sensible error
        }.to raise_error(Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotFindError)

        expect(entity_class.all.to_a).to be_empty
      end
    end

    describe "#hard_delete_all" do
      it "deletes everything" do
        entities = []

        entity_class.transaction do
          4.times do
            entity = entity_class.create(foo: 1, bar: :baz)
            entities << entity
          end

          # TODO: make calling #to_a not necessary
          expect(entity_class.all.to_a).to eq(entities)
        end

        entity_ids = entities.map(&:primary_key)

        expect(entity_ids).to contain_exactly(1, 2, 3, 4)

        entity_class.transaction do
          entities = []

          entity_class.all do |record|
            entities << record
          end

          entity_ids = entities.map(&:primary_key)

          expect(entity_ids).to contain_exactly(1, 2, 3, 4)

          4.times do
            entity = entity_class.create(foo: 1, bar: :baz)
            entities << entity
          end

          expect(entity_class.all).to match_array(entities)

          Foobara::Persistence.current_transaction(entities.first).hard_delete_all!(entity_class)

          expect(entities).to all be_hard_deleted
          expect(entity_class.all.to_a).to be_empty
        end

        entity_class.transaction do
          expect(entity_class.all.to_a).to be_empty
        end
      end
    end

    describe "#truncate" do
      it "deletes everything" do
        entity_class.transaction do
          4.times do
            entity_class.create(foo: 1, bar: :baz)
          end

          # TODO: make calling #to_a not necessary
          expect(entity_class.count).to eq(4)
        end

        entity_class.transaction do
          expect(entity_class.count).to eq(4)

          Foobara::Persistence.current_transaction(entity_class).truncate!

          expect(entity_class.count).to eq(0)
          expect(entity_class.all.to_a).to be_empty
        end

        entity_class.transaction do
          expect(entity_class.count).to eq(0)
          expect(entity_class.all.to_a).to be_empty
        end
      end
    end

    describe "#load_many" do
      it "loads many" do
        entities = nil
        entity_ids = nil

        entity_class.transaction do |tx|
          [
            { foo: 11, bar: :baz },
            { foo: 22, bar: :baz },
            { foo: 33, bar: :baz },
            { foo: 44, bar: :baz }
          ].map do |attributes|
            entity_class.create(attributes)
          end

          expect(entity_class.count).to eq(4)

          tx.flush!

          entities = entity_class.all

          expect(entities).to all be_a(Foobara::Entity)
          expect(entities.size).to eq(4)

          entity_ids = entities.map(&:primary_key)
          expect(entity_ids).to contain_exactly(1, 2, 3, 4)
        end

        entity_class.transaction do
          entity_class.load_many([entity_class.thunk(1)])
          loaded_entities = entity_class.load_many(entity_ids)
          expect(loaded_entities).to all be_loaded
          expect(loaded_entities).to eq(entities)
        end
      end
    end

    describe "#all_exist?" do
      it "answers whether they all exist or not" do
        entity_class.transaction do
          expect(entity_class.all_exist?([101, 102])).to be(false)

          [
            { foo: 11, bar: :baz, pk: 101 },
            { foo: 22, bar: :baz, pk: 102 },
            { foo: 33, bar: :baz },
            { foo: 44, bar: :baz }
          ].map do |attributes|
            entity_class.create(attributes)
          end

          entity_class.all do |record|
            expect(record).to_not be_persisted
          end

          expect(entity_class.all_exist?([101, 102])).to be(true)
          expect(entity_class.all_exist?([1, 2, 101, 102])).to be(false)
        end

        entity_class.transaction do
          expect(entity_class.all_exist?([1, 2, 101, 102])).to be(true)
          expect(entity_class.all_exist?([3])).to be(false)
        end
      end
    end

    describe "#unhard_delete!" do
      context "when record was dirty when hard deleted" do
        it "is still dirty" do
          entity = entity_class.transaction do
            entity_class.create(foo: 11, bar: :baz)
          end

          entity_class.transaction do
            entity = entity_class.thunk(entity.primary_key)

            expect(entity).to be_persisted

            expect(entity).to_not be_dirty

            entity.foo = 12

            expect(entity).to be_dirty
            expect(entity).to_not be_hard_deleted

            entity.foo = 11

            expect(entity).to_not be_dirty
            expect(entity).to_not be_hard_deleted

            entity.foo = 12

            expect(entity).to be_dirty
            expect(entity).to_not be_hard_deleted

            entity.hard_delete!

            expect(entity).to be_dirty
            expect(entity).to be_hard_deleted

            entity.unhard_delete!

            expect(entity).to be_dirty
            expect(entity).to_not be_hard_deleted
          end
        end
      end
    end

    describe "#exists?" do
      it "answers it exists or not" do
        entity_class.transaction do
          expect(entity_class.all_exist?([101, 102])).to be(false)

          entity_class.create(foo: 11, bar: :baz, pk: 101)

          expect(entity_class.exists?(101)).to be(true)

          entity_class.create(foo: 11, bar: :baz)

          expect(entity_class.exists?(1)).to be(false)
        end

        entity_class.transaction do
          expect(entity_class.exists?(101)).to be(true)

          expect(entity_class.exists?(1)).to be(true)
          expect(entity_class.exists?(2)).to be(false)
        end
      end
    end

    context "when creating a record with an already-in-use key" do
      it "explodes" do
        entity_class.transaction do
          entity_class.create(foo: 11, bar: :baz, pk: 101)
        end

        expect {
          entity_class.transaction do
            entity_class.create(foo: 11, bar: :baz, pk: 101)
          end
        }.to raise_error(Foobara::Persistence::EntityAttributesCrudDriver::Table::CannotInsertError)
      end
    end

    context "when restoring with a created record" do
      it "hard deletes it" do
        entity_class.transaction do |tx|
          record = entity_class.create(foo: 11, bar: :baz, pk: 101)

          tx.revert!

          expect(record).to be_hard_deleted
        end

        entity_class.transaction do
          expect(entity_class.count).to eq(0)
        end
      end
    end

    context "when persisting entity with an association" do
      let(:aggregate_class) do
        # TODO: refactor into a rspec helper for creating a properly stubbed class with a name
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        Class.new(Foobara::Entity) do
          class << self
            def name
              "SomeAggregate"
            end
          end

          stub_class.call(self)

          attributes pk: :integer,
                     foo: :integer,
                     some_entities: [SomeEntity]

          primary_key :pk
        end
      end

      it "writes the records to disk using primary keys" do
        some_entity2 = nil

        some_entity1 = entity_class.transaction do
          some_entity2 = entity_class.create(foo: 11, bar: :baz)
          entity_class.create(foo: 11, bar: :baz, pk: 101)
        end

        entity_class.transaction do
          some_entity3 = entity_class.create(foo: 11, bar: :baz, pk: 102)
          some_entity4 = entity_class.create(foo: 11, bar: :baz)

          aggregate_class.create(
            foo: 30,
            some_entities: [
              1,
              some_entity1,
              some_entity3,
              some_entity4
            ]
          )
        end

        entity_class.transaction do |tx|
          raw_records = aggregate_class.current_transaction_table.entity_attributes_crud_driver_table.records
          expect(raw_records.size).to eq(1)
          raw_record = raw_records[1]
          expect(raw_record[:some_entities]).to contain_exactly(1, 2, 101, 102)

          loaded_aggregate = aggregate_class.load(1)
          expect(loaded_aggregate.some_entities).to all be_a(SomeEntity)
          expect(loaded_aggregate.some_entities.map(&:primary_key)).to contain_exactly(1, 2, 101, 102)

          new_aggregate = aggregate_class.create(
            foo: 30,
            some_entities: [
              entity_class.create(foo: 11, bar: :baz)
            ]
          )

          expect(aggregate_class.contains_associations?).to be(true)
          expect(entity_class.contains_associations?).to be(false)

          tx.flush_created_record!(new_aggregate)
        end
      end
    end
  end
end
