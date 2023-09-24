RSpec.describe Foobara::Persistence::CrudDrivers::InMemoryMinimal do
  before do
    Foobara::Persistence.default_crud_driver = described_class.new
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

  describe "#find_by/#find_many_by" do
    it "can find by an attribute" do
      entity1 = entity2 = entity3 = entity4 = nil

      entity_class.transaction do
        entity1 = entity_class.new(foo: 11, bar: :baz)
        entity2 = entity_class.new(foo: 22, bar: :baz)
        entity3 = entity_class.new(foo: 33, bar: :basil)
        entity4 = entity_class.new(foo: 44, bar: :basil)

        # non-persisted records
        expect(entity_class.find_by(foo: "22")).to eq(entity2)
        expect(entity_class.find_many_by(foo: "11").to_a).to eq([entity1])
        expect(entity_class.find_many_by(bar: "basil").to_a).to eq([entity3, entity4])
      end

      entity_class.transaction do
        entity5 = entity_class.new(foo: 55, bar: :baz)
        entity6 = entity_class.new(foo: 66, bar: :baz)
        entity7 = entity_class.new(foo: 77, bar: :basil)
        entity8 = entity_class.new(foo: 88, bar: :basil)

        # mixture of persisted and non-persisted records
        expect(entity_class.find_by(foo: "22")).to eq(entity2)
        expect(entity_class.find_by(foo: "55")).to eq(entity5)

        expect(entity_class.find_many_by(foo: "11").to_a).to eq([entity1])
        expect(entity_class.find_many_by(foo: "66").to_a).to eq([entity6])
        expect(entity_class.find_many_by(bar: "basil").to_a).to eq([entity7, entity8, entity3, entity4])
      end
    end
  end
end
