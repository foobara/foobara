RSpec.describe Foobara::Namespace::AmbiguousRegistry do
  let(:registry) { described_class.new }

  let(:user_class) do
    Class.new do
      include Foobara::Scoped

      def initialize(full_name)
        self.scoped_name = full_name
      end
    end
  end

  context "when there's some conflicting entries" do
    let(:user1) do
      user_class.new("User")
    end

    let(:user2) do
      user_class.new("a::User")
    end

    let(:user3) do
      user_class.new("a::b::User")
    end

    let(:user4) do
      user_class.new("b::User")
    end

    let(:user4) do
      user_class.new("b::UniqueUser")
    end

    let(:user5) do
      user_class.new("a::b::c::d::User")
    end

    let(:users) { [user1, user2, user3, user4, user5] }

    before do
      registry.register(user1)
      registry.register(user2)
      registry.register(user3)
      registry.register(user4)
      registry.register(user5)
    end

    context "when looking up by full-paths" do
      it "returns the expected users" do
        users.each do |user|
          expect(registry.lookup(user.scoped_path)).to eq(user)
        end
      end
    end
  end
end
