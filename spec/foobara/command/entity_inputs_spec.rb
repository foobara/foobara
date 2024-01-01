RSpec.describe Foobara::Command do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    stub_class :User, Foobara::Entity do
      attributes id: :integer,
                 name: { type: :string, required: true },
                 fan_count: { type: :integer, default: 0 }
      primary_key :id
    end

    stub_class(:Fan, Foobara::Entity) do
      attributes id: :integer,
                 is_active: { type: :boolean, default: true },
                 fan_of: { type: :array, element_type_declaration: User, default: [] },
                 attrs: {
                   foo: { type: :symbol, required: true },
                   bar: [:integer],
                   duckfoo: :duck,
                   duckbar: [:duck]
                 }
      primary_key :id
    end

    stub_class :CreateUser, Foobara::Command do
      inputs User.attributes_type.declaration_data
      result User

      def execute
        create_user

        user
      end

      attr_accessor :user

      def create_user
        self.user = User.create(inputs)
      end
    end

    stub_class :CreateFan, Foobara::Command do
      inputs Fan.attributes_type.declaration_data
      result Fan

      def execute
        create_fan
        increment_fan_count

        fan
      end

      attr_accessor :fan

      def create_fan
        self.fan = Fan.create(inputs)
      end

      def increment_fan_count
        binding.pry
        fan.fan_of.each do |user|
          user.fan_count += 1
        end
      end
    end
  end

  describe ".possible_errors" do
    it "does not include creation errors for nested entities", :focus do
      # $stop = true
      # CreateFan.inputs_type.possible_errors
      # CreateFan.inputs_type.possible_errors
      # binding.pry
      # expect(CreateFan.possible_errors).to eq({})

      User.transaction do
        user1 = CreateUser.run!(name: "Some User1")
        user2 = CreateUser.run!(name: "Some User2")

        fan1 = CreateFan.run!(attrs: { foo: :bar }, fan_of: [user1])
        fan2 = CreateFan.run!(attrs: { foo: :baz }, fan_of: [user1, user2])
        fan3 = CreateFan.run!(attrs: { foo: :foo })

        expect(user1.fan_count).to eq(2)
        expect(user2.fan_count).to eq(1)
      end
    end
  end
end
