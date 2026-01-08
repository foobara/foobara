RSpec.describe Foobara::CommandConnector do
  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  after do
    Foobara.reset_alls
  end

  let(:command_class) do
    stub_class(:ComputeExponent, Foobara::Command) do
      inputs exponent: :integer, base: :integer
      result :integer

      def execute = base ** exponent
    end
  end

  let(:command_connector) do
    described_class.new(authenticator:, current_user: domain_user_class)
  end

  let(:auth_user_class) do
    stub_class "AuthUser", Foobara::Entity do
      attributes id: :integer, name: :string
      primary_key :id
    end
  end
  let(:domain_user_class) do
    auth_user_class
    stub_class "User", Foobara::Entity do
      attributes id: :integer, auth_user: AuthUser
      primary_key :id
    end
  end

  let(:auth_user) do
    auth_user_class.transaction { AuthUser.create(name: "Fumiko") }
  end
  let(:domain_user) do
    au = auth_user
    domain_user_class.transaction do
      User.create(auth_user: au)
    end
  end

  let(:authenticator) do
    user = auth_user
    Foobara::CommandConnector::Authenticator.subclass(to: AuthUser) { user }
  end

  let(:base) { 2 }
  let(:exponent) { 3 }

  let(:response) { command_connector.run(full_command_name:, action:, inputs:) }
  let(:errors_hash) { response.body.errors_hash }

  let(:action) { "run" }
  let(:full_command_name) { "ComputeExponent" }
  let(:inputs) do
    { base:, exponent: }
  end

  describe "#run_command" do
    class << self
      def with_current_user_allowed_rule
        let(:allowed_rule) do
          user = domain_user
          -> { current_user == user }
        end
      end

      def with_current_user_not_allowed_rule
        let(:allowed_rule) do
          -> { current_user == "asfdasdf" }
        end
      end

      def with_authenticated_user_allowed_rule
        let(:allowed_rule) do
          user = auth_user
          -> { authenticated_user == user }
        end
      end

      def with_authenticated_user_not_allowed_rule
        let(:allowed_rule) do
          -> { authenticated_user == "asfdasdf" }
        end
      end
    end

    shared_examples "a connector with auth mappers" do
      before do
        command_connector.connect(command_class, allowed_rule:)
      end

      context "when using current_user in the allowed rule" do
        context "when allowed" do
          with_current_user_allowed_rule

          it "runs the command" do
            expect(response.status).to be(0)
            expect(response.body).to eq(8)
          end
        end

        context "when not allowed" do
          with_current_user_not_allowed_rule

          it "fails with a relevant error" do
            expect(response.status).to be(1)
            expect(errors_hash.key?("runtime.not_allowed")).to be true
          end
        end

        context "when calling current_user multiple times" do
          let(:allowed_rule) do
            user = domain_user
            -> { current_user && current_user == user }
          end

          it "runs the command" do
            expect(response.status).to be(0)
            expect(response.body).to eq(8)
          end
        end
      end

      context "when using authenticated_user in the allowed rule" do
        context "when allowed" do
          with_authenticated_user_allowed_rule

          it "runs the command" do
            expect(response.status).to be(0)
            expect(response.body).to eq(8)
          end
        end

        context "when not allowed" do
          with_authenticated_user_not_allowed_rule

          it "fails with a relevant error" do
            expect(response.status).to be(1)
            expect(errors_hash.key?("runtime.not_allowed")).to be true
          end
        end
      end
    end

    context "when auth user mapper is an entity class" do
      before do
        domain_user
      end

      it_behaves_like "a connector with auth mappers"
    end
  end
end
