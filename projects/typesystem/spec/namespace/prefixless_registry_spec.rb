RSpec.describe Foobara::Namespace::PrefixlessRegistry do
  let(:registry) { described_class.new }

  let(:user_class) do
    Class.new do
      include Foobara::Scoped

      def initialize(full_name)
        self.scoped_name = full_name
      end
    end
  end

  let(:user) { user_class.new("User") }

  describe "#register" do
    it "registers the user and can look it up" do
      registry.register(user)
      expect(registry.lookup(user.scoped_path)).to eq(user)
    end

    context "when scoped has a prefix" do
      it "raises" do
        expect {
          registry.register(user_class.new("a::User"))
        }.to raise_error(Foobara::Namespace::PrefixlessRegistry::RegisteringScopedWithPrefixError)
      end
    end
  end
end
