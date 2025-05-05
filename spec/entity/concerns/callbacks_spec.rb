RSpec.describe Foobara::Entity::Concerns::Callbacks do
  around do |example|
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    Foobara::Persistence.default_base.transaction do
      example.run
    end
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

  describe ".after_any_action" do
    let(:record) { entity_class.create(foo: 10) }

    let(:calls) { [] }

    before do
      record.after_any_action do |**opts|
        calls << opts
      end
    end

    it "can create, load, and update records" do
      expect(calls).to be_empty
      expect(record).to be_dirty

      record.foo = 11

      expect(calls.size).to eq(1)
      expect(calls.last).to eq(
        record:,
        action: :attribute_changed,
        attribute_name: :foo,
        old_value: 10,
        new_value: 11
      )
    end
  end
end
