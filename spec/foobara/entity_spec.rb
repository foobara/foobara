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

  let(:loaded_and_persisted_record) do
    entity_class.new(
      pk: 1,
      foo: 5,
      bar: :baz
    )
  end
  let(:unloaded_and_persisted_record) do
    entity_class.new(1)
  end
  let(:not_persisted_record) do
    entity_class.new(
      foo: 5,
      bar: :baz
    )
  end

  describe "#loaded? and #persisted?" do
    it "gives the right answer for various contexts" do
      expect(loaded_and_persisted_record).to be_loaded
      expect(unloaded_and_persisted_record).to_not be_loaded
      expect(not_persisted_record).to_not be_loaded

      expect(loaded_and_persisted_record).to be_persisted
      expect(unloaded_and_persisted_record).to be_persisted
      expect(not_persisted_record).to_not be_persisted
    end
  end

  describe "setting primary key" do
    it "is not allowed unless it's the same" do
      not_persisted_record.pk = 6
      expect(not_persisted_record.primary_key).to eq(6)

      expect(loaded_and_persisted_record.primary_key).to eq(1)
      loaded_and_persisted_record.pk = "1"
      expect(loaded_and_persisted_record.primary_key).to eq(1)
      expect {
        loaded_and_persisted_record.pk = 13
      }.to raise_error(Foobara::Entity::UnexpectedPrimaryKeyChangeError)
    end
  end

  describe "equality methods" do
    describe "#== #hash and #eql?" do
      it "gives the expected result for various scenarios" do
        # rubocop:disable RSpec/IdenticalEqualityAssertion
        # ==
        expect(loaded_and_persisted_record).to eq(loaded_and_persisted_record)
        expect(unloaded_and_persisted_record).to eq(unloaded_and_persisted_record)
        expect(not_persisted_record).to eq(not_persisted_record)

        expect(loaded_and_persisted_record).to eq(unloaded_and_persisted_record)
        expect(loaded_and_persisted_record).to_not eq(not_persisted_record)

        expect(unloaded_and_persisted_record).to eq(loaded_and_persisted_record)
        expect(unloaded_and_persisted_record).to_not eq(not_persisted_record)

        expect(not_persisted_record).to_not eq(loaded_and_persisted_record)
        expect(not_persisted_record).to_not eq(unloaded_and_persisted_record)

        expect(entity_class.new(foo: 5, bar: :baz)).to_not eq(
          entity_class.new(foo: 5, bar: :baz)
        )

        # hash
        expect(loaded_and_persisted_record.hash).to eq(loaded_and_persisted_record.hash)
        expect(unloaded_and_persisted_record.hash).to eq(unloaded_and_persisted_record.hash)
        expect(not_persisted_record.hash).to eq(not_persisted_record.hash)

        expect(loaded_and_persisted_record.hash).to eq(unloaded_and_persisted_record.hash)
        expect(loaded_and_persisted_record.hash).to_not eq(not_persisted_record.hash)

        expect(unloaded_and_persisted_record.hash).to eq(loaded_and_persisted_record.hash)
        expect(unloaded_and_persisted_record.hash).to_not eq(not_persisted_record.hash)

        expect(not_persisted_record.hash).to_not eq(loaded_and_persisted_record.hash)
        expect(not_persisted_record.hash).to_not eq(unloaded_and_persisted_record.hash)

        # eql?
        expect(loaded_and_persisted_record).to eql(loaded_and_persisted_record)
        expect(unloaded_and_persisted_record).to eql(unloaded_and_persisted_record)
        expect(not_persisted_record).to eql(not_persisted_record)

        expect(loaded_and_persisted_record).to eql(unloaded_and_persisted_record)
        expect(loaded_and_persisted_record).to_not eql(not_persisted_record)

        expect(unloaded_and_persisted_record).to eql(loaded_and_persisted_record)
        expect(unloaded_and_persisted_record).to_not eql(not_persisted_record)

        expect(not_persisted_record).to_not eql(loaded_and_persisted_record)
        expect(not_persisted_record).to_not eql(unloaded_and_persisted_record)

        expect(entity_class.new(foo: 5, bar: :baz)).to_not eql(
          entity_class.new(foo: 5, bar: :baz)
        )
        # rubocop:enable RSpec/IdenticalEqualityAssertion
      end
    end
  end
end
