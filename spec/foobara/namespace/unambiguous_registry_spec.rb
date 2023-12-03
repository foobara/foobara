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

  let(:user2) { user_class.new("a::User") }
  let(:user4) { user_class.new("b::User") }

  context "when registering ambiguous entries" do
    it "raises" do
      registry.register(user2)

      expect {
        registry.register(user4)
      }.to raise_error(Foobara::Namespace::BaseRegistry::WouldMakeRegistryAmbiguousError)
    end
  end
end
