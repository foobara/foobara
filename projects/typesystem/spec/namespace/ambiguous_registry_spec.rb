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
    let(:user1) { user_class.new("User") }
    let(:user2) { user_class.new("a::User") }
    let(:user3) { user_class.new("a::b::User") }
    let(:user4) { user_class.new("b::User") }
    let(:user5) { user_class.new("b::UniqueUser") }
    let(:user6) { user_class.new("a::b::c::d::User") }
    let(:user7) { user_class.new("z::a::User") }
    let(:user8) { user_class.new("z::b::User") }

    let(:users) { [user1, user2, user3, user4, user5, user6, user7, user8] }

    before do
      users.each do |user|
        registry.register(user)
      end
    end

    context "when looking up by full-paths" do
      it "returns the expected users" do
        users.each do |user|
          expect(registry.lookup(user.scoped_path)).to eq(user)
        end
      end
    end

    context "when looking up by unambiguous key" do
      it "returns the expected users" do
        expect(registry.lookup(["d", "User"])).to eq(user6)
      end
    end

    context "when looking up by very ambiguous key" do
      it "raises" do
        expect {
          registry.lookup(["z", "User"])
        }.to raise_error(Foobara::Namespace::AmbiguousLookupError)
      end
    end

    context "when looking up by kind-of ambiguous key" do
      it "returns the best guess" do
        expect(registry.lookup(["a", "User"])).to eq(user2)
      end
    end

    describe "#unregister" do
      it "unregisters the element" do
        expect(registry.lookup(["z", "a", "User"])).to eq(user7)

        registry.unregister(user7)

        expect(registry.lookup(["z", "a", "User"])).to be_nil
      end
    end
  end
end
