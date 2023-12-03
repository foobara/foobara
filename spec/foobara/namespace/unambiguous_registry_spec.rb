RSpec.describe Foobara::Namespace::UnambiguousRegistry do
  let(:registry) { described_class.new }

  let(:user_class) do
    Class.new do
      include Foobara::Scoped

      def initialize(full_name)
        self.scoped_name = full_name
      end
    end
  end

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

  let(:user5) do
    user_class.new("b::UniqueUser")
  end

  let(:user6) do
    user_class.new("a::b::c::d::User")
  end

  context "registering ambiguous entries" do
    it "raises" do
      registry.register(user2)

      expect {
        registry.register(user4)
      }.to raise_error(Foobara::Namespace::UnambiguousRegistry::WouldMakeRegistryAmbiguousError)
    end
  end
end
