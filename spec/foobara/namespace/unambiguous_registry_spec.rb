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

  let(:user1) { user_class.new("a::User") }
  let(:user2) { user_class.new("b::User") }

  describe "#register" do
    context "when registering ambiguous entries" do
      it "raises" do
        registry.register(user1)

        expect {
          registry.register(user2)
        }.to raise_error(Foobara::Namespace::BaseRegistry::WouldMakeRegistryAmbiguousError)
      end
    end
  end

  describe "#unregister" do
    context "when not registered" do
      it "raises" do
        expect {
          registry.unregister(user1)
        }.to raise_error(Foobara::Namespace::BaseRegistry::NotRegisteredError)
      end
    end

    context "when registered" do
      before do
        registry.register(user1)
      end

      it "unregisters" do
        expect {
          registry.unregister(user1)
        }.to change { registry.registered?(user1.scoped_path) }.from(true).to(false)
      end
    end
  end
end
