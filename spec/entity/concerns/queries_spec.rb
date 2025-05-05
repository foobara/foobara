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

      attributes do
        id :integer
        name :string, :required
        stuff [:integer]
      end

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

  describe ".find_all_by_attribute_containing_any_of" do
    let(:user1) do
      user_class.create(name: "name1", stuff: [5, 6])
    end

    let(:user2) do
      user_class.create(name: "name2", stuff: [7, 8])
    end
    let(:user3) do
      user_class.create(name: "name3", stuff: [9, 10])
    end

    it "can find the records that contain the relevant values" do
      user_class.transaction do
        user1
        user2
        user3
      end

      user_class.transaction do
        users = user_class.find_all_by_attribute_containing_any_of(:stuff, [6, 9])
        expect(users.map(&:id)).to contain_exactly(1, 3)
      end
    end

    context "when records are created in the same transaction as the query" do
      it "can find the records that contain the relevant values" do
        user_class.transaction do
          user1
          user2
          user3

          expect(user_class.find_all_by_attribute_containing_any_of(:stuff, [6, 9])).to contain_exactly(user1, user3)
        end
      end
    end
  end
end
