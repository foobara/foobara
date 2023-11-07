RSpec.describe Foobara::Entity::Concerns::Queries do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:user_class) do
    stub_class = ->(klass) { stub_const(klass.name, klass) }

    Class.new(Foobara::Entity) do
      class << self
        def name
          "User"
        end
      end

      stub_class.call(self)

      attributes id: :integer, name: { type: :string, required: true }

      primary_key :id
    end
  end

  describe ".first" do
    context "when records do not exist" do
      it "is nil" do
        user_class.transaction do
          expect(user_class.first).to be_nil
        end
      end
    end

    context "when records exist" do
      before do
        user_class.transaction do
          user_class.create(name: "n1")
          user_class.create(name: "n2")
        end
      end

      it "fetches a record" do
        user_class.transaction do
          expect(user_class.first).to be_a(user_class)
        end
      end
    end
  end
end
