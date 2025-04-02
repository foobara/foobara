RSpec.describe Foobara::CommandPatternImplementation::Concerns::Reflection do
  after do
    Foobara.reset_alls
  end

  describe "#types_depended_on" do
    context "when command has no types at all" do
      subject { stub_class(:CommandClass, Foobara::Command).types_depended_on }

      it { is_expected.to be_empty }
    end
  end

  describe ".delegate_attribute" do
    let(:auth_user_class) do
      stub_class(:AuthUser, Foobara::Model) do
        attributes do
          username :string, :required
          email :string
        end
      end
    end
    let(:user_class) do
      auth_user

      stub_class(:User, Foobara::Model) do
        attributes do
          auth_user AuthUser, :required
        end
      end.tap do |klass|
        klass.delegate_attribute(:username, %i[auth_user username], writer:)
      end
    end

    let(:writer) { nil }
    let(:auth_user) { auth_user_class.new(username:, email:) }
    let(:username) { "Basil" }
    let(:email) { "basil@foobara.com" }

    let(:user) { user_class.new(auth_user:) }

    it "creates a reader" do
      expect(user.username).to eq(username)
      expect(user).to_not respond_to("username=")
      expect(user).to_not respond_to(email)
    end

    context "when creating writer method" do
      let(:writer) { true }

      it "creates a writer" do
        expect(user.username).to eq(username)
        expect(user).to respond_to("username=")
        expect(user).to_not respond_to(email)

        expect {
          user.username = "Barbara"
        }.to change(user, :username).to("Barbara")
      end
    end
  end
end
