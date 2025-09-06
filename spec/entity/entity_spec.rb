RSpec.describe Foobara::Entity do
  after do
    Foobara.reset_alls
  end

  let(:entity_class) do
    stub_class = ->(klass) { stub_const(klass.name, klass) }

    Class.new(described_class) do
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

  let(:attributes) do
    {
      foo: 12,
      bar: :baz
    }
  end

  context "with transaction" do
    around do |example|
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

      Foobara::Persistence.default_base.transaction do
        example.run
      end
    end

    before do
      # TODO: move these checks to a persistence_spec
      expect(Foobara::Persistence.object_to_base(entity_class)).to eq(Foobara::Persistence.default_base)
      expect(Foobara::Persistence.object_to_base(:default_entity_base)).to eq(Foobara::Persistence.default_base)
      expect(Foobara::Persistence.object_to_base("default_entity_base")).to eq(Foobara::Persistence.default_base)

      Foobara::Persistence.transaction(entity_class, mode: :open_new) do
        loaded_and_persisted_record
      end

      # TODO: implement a no-transaction-required type of mode
      unloaded_thunk_record
      not_persisted_record
    end

    let(:loaded_and_persisted_record) do
      entity_class.create(attributes)
    end
    let(:unloaded_thunk_record) do
      entity_class.thunk(pk)
    end
    let(:not_persisted_record) do
      # Just testing some un-tested code with this pointless transaction block...
      transactions = [Foobara::Persistence.default_base.current_transaction]
      Foobara::Persistence::EntityBase.using_transactions(transactions) do
        entity_class.create(attributes)
      end
    end

    let(:pk) { loaded_and_persisted_record.pk }

    describe "#loaded? and #persisted?" do
      it "gives the right answer for various contexts" do
        expect(loaded_and_persisted_record.pk).to be_an(Integer)

        expect(loaded_and_persisted_record).to be_loaded
        expect(unloaded_thunk_record).to_not be_loaded
        expect(not_persisted_record).to_not be_loaded

        expect(loaded_and_persisted_record).to be_persisted
        expect(unloaded_thunk_record).to be_persisted
        expect(not_persisted_record).to_not be_persisted
      end
    end

    describe "setting primary key" do
      it "is not allowed unless it's the same" do
        not_persisted_record.pk = 6
        expect(not_persisted_record.primary_key).to eq(6)

        expect(loaded_and_persisted_record.primary_key).to eq(1)
        entity_class.transaction(mode: :use_existing) do
          record = entity_class.thunk(loaded_and_persisted_record.primary_key)
          expect(record.primary_key).to eq(1)
          record.pk = "1"
          expect(record.primary_key).to eq(1)
          expect {
            record.pk = 13
          }.to raise_error(Foobara::Entity::UnexpectedPrimaryKeyChangeError)
        end
      end
    end

    describe "#write_attribute_without_callbacks!" do
      it "blows up on invalid values" do
        record = entity_class.create

        record.write_attribute_without_callbacks!(:foo, 5)
        expect(record.foo).to eq(5)

        expect {
          record.write_attribute_without_callbacks!(:foo, "asdf")
        }.to raise_error(Foobara::Value::Processor::Casting::CannotCastError)
      end
    end
  end

  describe ".model_type.process_value!" do
    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    end

    context "when record comes from a different closed transaction" do
      let(:record_from_a_different_transaction) do
        entity_class.transaction do
          entity_class.create(attributes)
        end
      end

      it "casts it to a new thunk from the current transaction using its primary key" do
        record_from_a_different_transaction

        cast_value = entity_class.transaction do
          entity_class.model_type.process_value!(record_from_a_different_transaction)
        end

        expect(cast_value).to be_a(entity_class)
        expect(cast_value.pk).to eq(record_from_a_different_transaction.pk)
        expect(cast_value.object_id).to_not eq(record_from_a_different_transaction.object_id)
      end
    end
  end

  describe "equality methods" do
    let(:loaded_and_persisted_record) do
      entity_class.build(attributes.merge(pk:)).tap do |record|
        record.is_persisted = true
        record.is_loaded = true

        expect(record).to be_persisted
        expect(record).to be_loaded
      end
    end
    let(:unloaded_thunk_record) do
      entity_class.build(pk:)
    end
    let(:not_persisted_record) do
      entity_class.build(attributes)
    end
    let(:not_persisted_record_with_pk) do
      entity_class.build(attributes.merge(pk:))
    end

    let(:pk) { 10 }

    describe "#== #hash and #eql?" do
      it "gives the expected result for various scenarios" do
        # rubocop:disable RSpec/IdenticalEqualityAssertion
        # ==
        expect(loaded_and_persisted_record).to eq(loaded_and_persisted_record)
        expect(unloaded_thunk_record).to eq(unloaded_thunk_record)
        expect(not_persisted_record).to eq(not_persisted_record)
        expect(not_persisted_record_with_pk).to eq(not_persisted_record_with_pk)

        expect(loaded_and_persisted_record).to eq(unloaded_thunk_record)
        expect(loaded_and_persisted_record).to_not eq(not_persisted_record)
        # Tricky to think of what this comparison should be.
        # One thought would be that they are not equal and persisting the non-persisted one should result
        # in an error. But will go with considering them equal for now and maybe revisit.
        expect(loaded_and_persisted_record).to eq(not_persisted_record_with_pk)

        expect(unloaded_thunk_record).to eq(loaded_and_persisted_record)
        expect(unloaded_thunk_record).to_not eq(not_persisted_record)
        expect(unloaded_thunk_record).to eq(not_persisted_record_with_pk)

        expect(not_persisted_record).to_not eq(loaded_and_persisted_record)
        expect(not_persisted_record).to_not eq(unloaded_thunk_record)
        expect(not_persisted_record).to_not eq(not_persisted_record_with_pk)

        expect(entity_class.build(attributes.dup)).to_not eq(entity_class.build(attributes.dup))

        # hash
        expect(loaded_and_persisted_record.hash).to eq(loaded_and_persisted_record.hash)
        expect(unloaded_thunk_record.hash).to eq(unloaded_thunk_record.hash)
        expect(not_persisted_record.hash).to eq(not_persisted_record.hash)
        expect(not_persisted_record_with_pk.hash).to eq(not_persisted_record_with_pk.hash)

        expect(loaded_and_persisted_record.hash).to eq(unloaded_thunk_record.hash)
        expect(loaded_and_persisted_record.hash).to_not eq(not_persisted_record.hash)
        expect(loaded_and_persisted_record.hash).to eq(not_persisted_record_with_pk.hash)

        expect(unloaded_thunk_record.hash).to eq(loaded_and_persisted_record.hash)
        expect(unloaded_thunk_record.hash).to_not eq(not_persisted_record.hash)
        expect(unloaded_thunk_record.hash).to eq(not_persisted_record_with_pk.hash)

        expect(not_persisted_record.hash).to_not eq(loaded_and_persisted_record.hash)
        expect(not_persisted_record.hash).to_not eq(unloaded_thunk_record.hash)
        expect(not_persisted_record.hash).to_not eq(not_persisted_record_with_pk.hash)

        # eql?
        expect(loaded_and_persisted_record).to eql(loaded_and_persisted_record)
        expect(unloaded_thunk_record).to eql(unloaded_thunk_record)
        expect(not_persisted_record).to eql(not_persisted_record)
        expect(not_persisted_record_with_pk).to eql(not_persisted_record_with_pk)

        expect(loaded_and_persisted_record).to eql(unloaded_thunk_record)
        expect(loaded_and_persisted_record).to_not eql(not_persisted_record)
        expect(loaded_and_persisted_record).to eql(not_persisted_record_with_pk)

        expect(unloaded_thunk_record).to eql(loaded_and_persisted_record)
        expect(unloaded_thunk_record).to_not eql(not_persisted_record)
        expect(unloaded_thunk_record).to eql(not_persisted_record_with_pk)

        expect(not_persisted_record).to_not eql(loaded_and_persisted_record)
        expect(not_persisted_record).to_not eql(unloaded_thunk_record)
        expect(not_persisted_record).to_not eql(not_persisted_record_with_pk)

        expect(entity_class.build(attributes.dup)).to_not eql(entity_class.build(attributes.dup))
        # rubocop:enable RSpec/IdenticalEqualityAssertion
      end
    end
  end

  describe "#inpsect" do
    subject { entity_class.build(pk: 5).inspect }

    it { is_expected.to eq("<SomeEntity:5>") }
  end
end
