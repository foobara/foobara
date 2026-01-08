RSpec.describe Foobara::CommandConnector do
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
    described_class.new(authenticator:, current_user: current_user_mapper)
  end

  let(:authenticator) do
    proc { "some_user" }
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
          -> { current_user == "current_user is some_user" }
        end
      end

      def with_current_user_not_allowed_rule
        let(:allowed_rule) do
          -> { current_user == "asfdasdf" }
        end
      end

      def with_authenticated_user_allowed_rule
        let(:allowed_rule) do
          -> { authenticated_user == "some_user" }
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
            -> { current_user && current_user == "current_user is some_user" }
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

    context "when auth user mapper is a hash" do
      let(:current_user_mapper) do
        {
          to: :string,
          map: ->(authenticated_user) { "current_user is #{authenticated_user}" }
        }
      end

      it_behaves_like "a connector with auth mappers"
    end

    context "when auth user mapper is an array" do
      let(:current_user_mapper) { [:string, ->(authenticated_user) { "current_user is #{authenticated_user}" }] }

      it_behaves_like "a connector with auth mappers"
    end

    context "when auth user mapper is a typed transformer class" do
      let(:current_user_mapper) do
        stub_class("SomeTypedTransformer", Foobara::TypeDeclarations::TypedTransformer) do
          to :string

          def transform(authenticated_user)
            "current_user is #{authenticated_user}"
          end
        end
      end

      it_behaves_like "a connector with auth mappers"

      context "when it is an instance" do
        let(:current_user_mapper) { super().instance }

        it_behaves_like "a connector with auth mappers"
      end
    end

    context "when auth user mapper is a domain mapper" do
      let(:current_user_mapper) do
        stub_class("SomeDomainMapper", Foobara::DomainMapper) do
          from :string
          to :string

          def map = "current_user is #{from}"
        end
      end

      it_behaves_like "a connector with auth mappers"
    end

    context "when auth user mapper is a command" do
      context "with only one input" do
        let(:current_user_mapper) do
          stub_class("SomeCommand", Foobara::Command) do
            inputs auth_user: :string
            result :string

            def execute = "current_user is #{auth_user}"
          end
        end

        it_behaves_like "a connector with auth mappers"
      end

      context "with multiple inputs but only one required input" do
        let(:current_user_mapper) do
          stub_class("SomeCommand", Foobara::Command) do
            inputs do
              foo :string
              bar :string
              auth_user :string, :required
            end
            result :string

            def execute = "current_user is #{auth_user}"
          end
        end

        it_behaves_like "a connector with auth mappers"
      end
    end
  end
end
