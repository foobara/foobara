Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Http do
  let(:command_class) do
    stub_class = ->(klass) { stub_const(klass.name, klass) }

    Class.new(Foobara::Command) do
      class << self
        def name
          "ComputeExponential"
        end
      end

      stub_class.call(self)

      inputs exponent: :integer,
             base: :integer
      result :integer

      attr_accessor :exponential

      def execute
        compute

        exponential
      end

      def compute
        self.exponential = 1

        exponent.times do
          self.exponential *= base
        end
      end
    end
  end

  let(:command_connector) do
    described_class.new(authenticator:)
  end

  let(:authenticator) { nil }

  let(:base) { 2 }
  let(:exponent) { 3 }

  let(:request) { command_connector.run(path:, method:, headers:, query_string:, body:) }
  let(:response) { request.response }
  let(:outcome) { request.outcome }
  let(:result) { request.result }

  let(:path) { "/run/ComputeExponential" }
  let(:method) { "POST" }
  let(:headers) { { some_header_name: "some_header_value" } }
  let(:query_string) { "base=#{base}" }
  let(:body) { "{\"exponent\":#{exponent}}" }
  let(:inputs_transformers) { nil }
  let(:result_transformers) { nil }
  let(:errors_transformers) { nil }
  let(:allowed_rule) { nil }
  let(:allowed_rules) { nil }
  let(:requires_authentication) { nil }

  describe "#run_command" do
    before do
      if allowed_rules
        command_connector.allowed_rules(allowed_rules)
      end

      command_connector.connect(
        command_class,
        inputs_transformers:,
        result_transformers:,
        errors_transformers:,
        allowed_rule:,
        requires_authentication:
      )
    end

    it "runs the command" do
      expect(outcome).to be_success
      expect(result).to be(8)

      expect(response.status).to be(200)
      expect(response.headers).to eq({})
      expect(response.body).to eq("8")
    end

    context "with default transformers" do
      before do
        identity = proc { |x| x }

        command_connector.add_default_inputs_transformer(identity)
        command_connector.add_default_result_transformer(identity)
        command_connector.add_default_errors_transformer(identity)
      end

      it "runs the command" do
        expect(outcome).to be_success
        expect(result).to be(8)

        expect(response.status).to be(200)
        expect(response.headers).to eq({})
        expect(response.body).to eq("8")
      end
    end

    context "when inputs are bad" do
      let(:query_string) { "some_bad_input=10" }

      it "fails" do
        expect(outcome).to_not be_success

        expect(response.status).to be(422)
        expect(response.headers).to eq({})

        error = JSON.parse(response.body)["data.unexpected_attributes"]
        unexpected_attributes = error["context"]["unexpected_attributes"]

        expect(unexpected_attributes).to eq(["some_bad_input"])
      end
    end

    context "when unknown error" do
      before do
        command_class.define_method :execute do
          raise "kaboom!"
        end
      end

      it "fails" do
        expect(outcome).to_not be_success

        expect(response.status).to be(500)
        expect(response.headers).to eq({})

        error = JSON.parse(response.body)["runtime.unknown"]

        expect(error["message"]).to eq("kaboom!")
        expect(error["is_fatal"]).to be(true)
      end
    end

    context "with various transformers" do
      let(:query_string) { "bbaassee=#{base}" }

      let(:inputs_transformers) { [inputs_transformer] }
      let(:inputs_transformer) do
        Class.new(Foobara::Value::Transformer) do
          def transform(inputs)
            {
              base: inputs["bbaassee"],
              exponent: inputs["exponent"]
            }
          end
        end
      end

      let(:result_transformers) { [->(result) { result * 2 }] }
      let(:errors_transformers) { [->(errors) { errors }] }

      it "runs the command" do
        expect(outcome).to be_success
        expect(result).to be(16)

        expect(response.status).to be(200)
        expect(response.headers).to eq({})
        expect(response.body).to eq("16")
      end

      context "when error" do
        let(:query_string) { "foo=bar" }

        it "is not success" do
          expect(outcome).to_not be_success
          errors = request.errors

          expect(errors.size).to eq(1)

          error = errors.first

          expect(error.symbol).to eq(:cannot_cast)

          expect(response.status).to be(422)
          expect(response.headers).to eq({})
          expect(response.body).to include("cannot_cast")
        end
      end

      context "with multiple transformers" do
        let(:identity) { ->(x) { x } }

        let(:inputs_transformers) { [identity, inputs_transformer] }
        let(:result_transformers) { [->(result) { result * 2 }, identity] }
        let(:errors_transformers) { [->(errors) { errors }, identity] }

        it "runs the command" do
          expect(outcome).to be_success
          expect(result).to be(16)

          expect(response.status).to be(200)
          expect(response.headers).to eq({})
          expect(response.body).to eq("16")
        end

        context "when error" do
          let(:query_string) { "foo=bar" }

          it "is not success" do
            expect(outcome).to_not be_success
            errors = request.errors

            expect(errors.size).to eq(1)

            error = errors.first

            expect(error.symbol).to eq(:cannot_cast)

            expect(response.status).to be(422)
            expect(response.headers).to eq({})
            expect(response.body).to include("cannot_cast")
          end
        end
      end

      context "with transformer instance instead of class" do
        let(:inputs_transformers) { [inputs_transformer.instance] }

        it "runs the command" do
          expect(outcome).to be_success
          expect(result).to be(16)

          expect(response.status).to be(200)
          expect(response.headers).to eq({})
          expect(response.body).to eq("16")
        end
      end
    end

    context "with allowed rule" do
      context "when declared with a hash" do
        let(:allowed_rule) do
          logic = proc { base == 2 }

          {
            logic:,
            symbol: :must_be_base_2
          }
        end

        context "when allowed" do
          it "runs the command" do
            expect(request).to respond_to(:base)

            expect(outcome).to be_success
            expect(result).to be(8)

            expect(response.status).to be(200)
            expect(response.headers).to eq({})
            expect(response.body).to eq("8")
          end
        end

        context "when not allowed" do
          let(:allowed_rule) do
            logic = proc { base == 1900 }

            {
              logic:,
              symbol: :must_be_base_1900,
              explanation: proc { "Must be 1900 but was #{base}" }
            }
          end

          it "fails with 403 and relevant error" do
            expect(outcome).to_not be_success

            expect(response.status).to be(403)
            expect(response.headers).to eq({})
            expect(JSON.parse(response.body)["runtime.not_allowed"]["message"]).to eq("Must be 1900 but was 2")
          end
        end
      end

      context "when declared with the rule registry" do
        let(:allowed_rules) do
          {
            must_be_base_2: {
              logic: proc { base == 2 },
              explanation: "Must be base 2"
            },
            must_be_base_1900: {
              logic: proc { base == 1900 },
              explanation: proc { "Must be base 1900 but was #{base}" }
            }
          }
        end

        context "when allowed" do
          let(:allowed_rule) { [:must_be_base_1900, "must_be_base_2"] }

          it "runs the command" do
            expect(request).to respond_to(:base)

            expect(outcome).to be_success
            expect(result).to be(8)

            expect(response.status).to be(200)
            expect(response.headers).to eq({})
            expect(response.body).to eq("8")
          end
        end

        context "when not allowed" do
          let(:allowed_rule) do
            :must_be_base_1900
          end

          it "fails with 401 and relevant error" do
            expect(command_connector.command_registry[ComputeExponential].command_class).to eq(ComputeExponential)

            expect(outcome).to_not be_success

            expect(response.status).to be(403)
            expect(response.headers).to eq({})
            expect(JSON.parse(response.body)["runtime.not_allowed"]["message"]).to eq("Must be base 1900 but was 2")
          end
        end
      end

      context "when declared with a proc" do
        context "without explanation" do
          let(:allowed_rule) do
            proc { base == 1900 }
          end

          it "fails with 401 and relevant error" do
            expect(outcome).to_not be_success

            expect(response.status).to be(403)
            expect(response.headers).to eq({})
            expect(JSON.parse(response.body)["runtime.not_allowed"]["message"]).to match(/base == 1900/)
          end
        end
      end
    end

    context "when authentication required" do
      let(:requires_authentication) { true }

      context "when unauthenticated" do
        it "is 401" do
          expect(outcome).to_not be_success

          expect(response.status).to be(401)
          expect(response.headers).to eq({})
          expect(JSON.parse(response.body).keys).to eq(["runtime.unauthenticated"])
        end
      end

      context "when authenticated" do
        let(:authenticator) do
          # normally we would return a user but we'll just generate a pointless integer
          # to test proxying to the request
          proc { path.length }
        end

        it "is 200" do
          expect(outcome).to be_success

          expect(response.status).to be(200)
          expect(response.headers).to eq({})
          expect(JSON.parse(response.body)).to eq(8)
        end
      end
    end

    context "with an entity input" do
      before do
        Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
      end

      after do
        Foobara.reset_alls
      end

      let(:command_class) do
        user_class

        stub_class = ->(klass) { stub_const(klass.name, klass) }

        Class.new(Foobara::Command) do
          class << self
            def name
              "QueryUser"
            end
          end

          stub_class.call(self)

          inputs user: User
          result :User

          load_all

          def execute
            user
          end
        end
      end

      let(:path) { "/run/QueryUser" }
      let(:query_string) { "user=#{user_id}" }
      let(:body) { "" }

      let(:result_transformers) {
        [proc { |user| user.attributes }]
      }

      let(:user_class) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        Class.new(Foobara::Entity) do
          class << self
            def name
              "User"
            end
          end

          stub_class.call(self)

          attributes id: :integer,
                     name: :string,
                     ratings: [:integer]
          primary_key :id
        end
      end

      context "when user exists" do
        let(:user_id) do
          User.transaction do
            User.create(name: :whatever)
          end.id
        end

        it "finds the user" do
          expect(outcome).to be_success

          expect(response.status).to be(200)
          expect(response.headers).to eq({})
          expect(JSON.parse(response.body)).to eq("id" => user_id, "name" => "whatever")
        end
      end

      context "when not found error" do
        let(:user_id) { 100 }

        it "fails" do
          expect(outcome).to_not be_success

          expect(response.status).to be(404)
          expect(response.headers).to eq({})

          errors = JSON.parse(response.body)

          expect(errors.size).to eq(1)
          expect(errors.keys.first).to eq("runtime.user_not_found")
        end
      end

      context "with an association" do
        let(:referral_class) do
          stub_class = ->(klass) { stub_const(klass.name, klass) }

          Class.new(Foobara::Entity) do
            class << self
              def name
                "Referral"
              end
            end

            stub_class.call(self)

            attributes id: :integer, email: :email
            primary_key :id
          end
        end

        before do
          User.attributes referral: referral_class
        end

        context "with AtomicSerializer" do
          let(:result_transformers) { described_class::Serializers::AtomicSerializer }

          context "when user exists with a referral" do
            let(:user) do
              User.transaction do
                referral = referral_class.create(email: "Some@email.com")
                User.create(name: "Some Name", referral:, ratings: [1, 2, 3])
              end
            end
            let(:user_id) { user.id }

            let(:referral_id) {  user.referral.id }

            it "serializes as an atom" do
              expect(outcome).to be_success

              expect(response.status).to be(200)
              expect(response.headers).to eq({})
              expect(JSON.parse(response.body)).to eq(
                "id" => user_id,
                "name" => "Some Name",
                "referral" => referral_id,
                "ratings" => [1, 2, 3]
              )
            end
          end
        end
      end
    end

    context "without querystring" do
      let(:query_string) { "" }
      let(:body) { "{\"exponent\":#{exponent},\"base\":#{base}}" }

      it "runs the command" do
        expect(outcome).to be_success
        expect(result).to be(8)

        expect(response.status).to be(200)
        expect(response.headers).to eq({})
        expect(response.body).to eq("8")
      end
    end

    describe "connector manifest" do
      describe "#command_manifest" do
        let(:command_manifest) { command_connector.command_manifest }

        it "returns metadata about the commands" do
          expect(
            command_manifest[:global_organization][:global_domain][:commands][:ComputeExponential][:result_type]
          ).to eq(type: :integer)
        end

        context "with an entity input" do
          before do
            Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
          end

          after do
            Foobara.reset_alls
          end

          let(:command_class) do
            user_class

            stub_class = ->(klass) { stub_const(klass.name, klass) }

            Class.new(Foobara::Command) do
              class << self
                def name
                  "QueryUser"
                end
              end

              stub_class.call(self)

              inputs user: User
              result :User
            end
          end

          let(:path) { "/run/QueryUser" }
          let(:query_string) { "user=#{user_id}" }
          let(:body) { "" }

          let(:result_transformers) {
            [proc { |user| user.attributes }]
          }

          let(:user_class) do
            stub_class = ->(klass) { stub_const(klass.name, klass) }

            Class.new(Foobara::Entity) do
              class << self
                def name
                  "User"
                end
              end

              stub_class.call(self)

              attributes id: :integer, name: :string
              primary_key :id
            end
          end

          it "returns metadata about the types" do
            expect(
              command_manifest[:global_organization][:global_domain][:types].keys
            ).to match_array(
              %i[
                User
                associative_array
                atomic_duck
                attributes
                duck
                duckture
                entity
                integer
                model
                number
                string
              ]
            )
          end
        end
      end
    end
  end
end
