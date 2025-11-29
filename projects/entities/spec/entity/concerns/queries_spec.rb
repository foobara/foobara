RSpec.describe Foobara::Entity::Concerns::Queries do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:user_class) do
    stub_class "User", Foobara::Entity do
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

  describe ".load" do
    context "when the record is already loaded" do
      it "returns the record" do
        user = user_class.transaction do
          user_class.create(name: "Basil")
        end

        user_class.transaction do
          user = user_class.load(user.id)
          expect(user).to be_a(user_class)
          expect(user.name).to eq("Basil")
          user = user_class.load(user)
          expect(user).to be_a(user_class)
          expect(user.name).to eq("Basil")
        end
      end
    end

    context "with load_paths:" do
      let(:outer_entity) do
        user_class

        stub_class "Outer", Foobara::Entity do
          attributes do
            id :integer
            stuff :required do
              users [User], :required
            end
          end

          primary_key :id
        end
      end

      let(:outer_record) do
        outer_entity.transaction do
          outer_entity.create(stuff: { users: })
        end
      end

      let(:users) do
        (0..3).map do |i|
          User.create(name: "name#{i}")
        end
      end

      it "can load records with various types of load_paths specified in different ways" do
        record_id = outer_record.id

        record = outer_entity.transaction do
          outer_entity.load(record_id)
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([false, false, false, false])

        record = outer_entity.transaction do
          outer_entity.load(record_id, load_paths: "stuff.users.2")
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([false, false, true, false])

        record = outer_entity.transaction do
          outer_entity.load(record_id, load_paths: ["stuff.users.2"])
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([false, false, true, false])

        record = outer_entity.transaction do
          outer_entity.load(record_id, load_paths: ["stuff", "users", "2"])
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([false, false, true, false])

        record = outer_entity.transaction do
          outer_entity.load(record_id, load_paths: [:stuff, :users, :"2"])
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([false, false, true, false])

        record = outer_entity.transaction do
          outer_entity.load(record_id, load_paths: [[:stuff, :users, :"2"]])
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([false, false, true, false])

        record = outer_entity.transaction do
          outer_entity.load(record_id, load_paths: [[:stuff, :users, :"#"]])
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([true, true, true, true])

        record = outer_entity.transaction do
          outer_entity.load(record_id, load_paths: [[:stuff, :users]])
        end
        expect(record).to be_a(outer_entity)
        expect(record.stuff[:users].map(&:loaded?)).to eq([true, true, true, true])
      end
    end
  end
end
