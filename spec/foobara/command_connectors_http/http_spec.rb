Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Http do
  let(:command_class) do
    stub_class = ->(klass) { stub_const(klass.name, klass) }

    Class.new(Foobara::Command) do
      error_klass = Class.new(Foobara::RuntimeError) do
        class << self
          def name
            "SomeRuntimeError"
          end

          def context_type_declaration
            :duck
          end
        end

        stub_class.call(self)
      end

      possible_error error_klass

      class << self
        def name
          "ComputeExponent"
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
    described_class.new(authenticator:, default_serializers:)
  end

  let(:authenticator) { nil }
  let(:default_serializers) do
    [Foobara::CommandConnectors::ErrorsSerializer, Foobara::CommandConnectors::JsonSerializer]
  end

  let(:base) { 2 }
  let(:exponent) { 3 }

  let(:response) { command_connector.run(path:, method:, headers:, query_string:, body:) }

  let(:path) { "/run/ComputeExponent" }
  let(:method) { "POST" }
  let(:headers) { { some_header_name: "some_header_value" } }
  let(:query_string) { "base=#{base}" }
  let(:body) { "{\"exponent\":#{exponent}}" }
  let(:inputs_transformers) { nil }
  let(:result_transformers) { nil }
  let(:errors_transformers) { nil }
  let(:pre_commit_transformers) { nil }
  let(:serializers) { nil }
  let(:allowed_rule) { nil }
  let(:allowed_rules) { nil }
  let(:requires_authentication) { nil }
  let(:capture_unknown_error) { false }
  let(:aggregate_entities) { nil }

  describe "#connect" do
    context "when command is in an organization" do
      let!(:org_module) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        Module.new do
          class << self
            def name
              "SomeOrg"
            end
          end

          stub_class.call(self)

          foobara_organization!
        end
      end

      let!(:domain_module) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        SomeOrg.module_eval do
          Module.new do
            class << self
              def name
                "SomeOrg::SomeDomain"
              end
            end

            stub_class.call(self)

            foobara_domain!
          end
        end
      end

      let!(:command_class) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        SomeOrg::SomeDomain.module_eval do
          Class.new(Foobara::Command) do
            class << self
              def name
                "SomeOrg::SomeDomain::SomeCommand"
              end
            end

            stub_class.call(self)
          end
        end
      end

      it "registers the command" do
        command_connector.connect(org_module)

        transformed_commands = command_connector.command_registry.registry.values
        expect(transformed_commands.size).to eq(1)
        expect(transformed_commands.first.command_class).to eq(command_class)
      end

      context "when registering via domain" do
        it "registers the command" do
          command_connector.connect(domain_module)

          transformed_commands = command_connector.command_registry.registry.values
          expect(transformed_commands.size).to eq(1)
          expect(transformed_commands.first.command_class).to eq(command_class)
        end
      end
    end
  end

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
        serializers:,
        allowed_rule:,
        requires_authentication:,
        pre_commit_transformers:,
        capture_unknown_error:,
        aggregate_entities:
      )
    end

    it "runs the command" do
      expect(response.status).to be(200)
      expect(response.headers).to be_a(Hash)
      expect(response.body).to eq("8")
    end

    context "with a header set via env var..." do
      stub_env_vars FOOBARA_HTTP_RESPONSE_HEADER_SOME_VAR: "some value",
                    FOOBARA_HTTP_RESPONSE_HEADER_CONTENT_TYPE: "application/json"

      it "runs the command" do
        expect(response.status).to be(200)
        expect(response.headers["content-type"]).to eq("application/json")
        expect(response.headers["some-var"]).to eq("some value")
        expect(response.body).to eq("8")
      end
    end

    context "with default transformers" do
      before do
        identity = proc { |x| x }

        command_connector.add_default_inputs_transformer(identity)
        command_connector.add_default_result_transformer(identity)
        command_connector.add_default_errors_transformer(identity)
        command_connector.add_default_pre_commit_transformer(identity)
      end

      let(:default_serializers) { Foobara::CommandConnectors::JsonSerializer }

      it "runs the command" do
        expect(response.status).to be(200)
        expect(response.headers).to be_a(Hash)
        expect(response.body).to eq("8")
      end
    end

    context "without serializers" do
      let(:default_serializers) { nil }

      it "runs the command" do
        expect(response.status).to be(200)
        expect(response.headers).to be_a(Hash)
        expect(response.body).to eq(8)
      end
    end

    context "when inputs are bad" do
      let(:query_string) { "some_bad_input=10" }

      let(:default_serializers) { Foobara::CommandConnectors::JsonSerializer }
      let(:serializers) { Foobara::CommandConnectors::ErrorsSerializer }

      it "fails" do
        expect(response.status).to be(422)
        expect(response.headers).to be_a(Hash)

        error = JSON.parse(response.body).find { |e| e["key"] == "data.unexpected_attributes" }
        unexpected_attributes = error["context"]["unexpected_attributes"]

        expect(unexpected_attributes).to eq(["some_bad_input"])
      end
    end

    context "when unknown error" do
      let(:capture_unknown_error) { true }
      let(:default_serializers) do
        [Foobara::CommandConnectors::ErrorsSerializer, Foobara::CommandConnectors::JsonSerializer]
      end

      before do
        command_class.define_method :execute do
          raise "kaboom!"
        end
      end

      it "fails" do
        expect(response.status).to be(500)
        expect(response.headers).to be_a(Hash)

        error = JSON.parse(response.body).find { |e| e["key"] == "runtime.unknown" }

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
        expect(response.status).to be(200)
        expect(response.headers).to be_a(Hash)
        expect(response.body).to eq("16")
      end

      context "when error" do
        let(:query_string) { "foo=bar" }

        it "is not success" do
          expect(response.status).to be(422)
          expect(response.headers).to be_a(Hash)
          expect(response.body).to include("cannot_cast")
        end
      end

      context "with multiple transformers" do
        let(:identity) { ->(x) { x } }

        let(:inputs_transformers) { [identity, inputs_transformer] }
        let(:result_transformers) { [->(result) { result * 2 }, identity] }
        let(:errors_transformers) { [identity, identity] }
        let(:pre_commit_transformers) { [identity, identity] }

        it "runs the command" do
          expect(response.status).to be(200)
          expect(response.headers).to be_a(Hash)
          expect(response.body).to eq("16")
        end

        context "when error" do
          let(:query_string) { "foo=bar" }

          it "is not success" do
            expect(response.status).to be(422)
            expect(response.headers).to be_a(Hash)
            expect(response.body).to include("cannot_cast")
          end
        end
      end

      context "with transformer instance instead of class" do
        let(:inputs_transformers) { [inputs_transformer.instance] }

        it "runs the command" do
          expect(response.status).to be(200)
          expect(response.headers).to be_a(Hash)
          expect(response.body).to eq("16")
        end
      end
    end

    context "with allowed rule" do
      context "when declared with a hash" do
        let(:allowed_rule) do
          logic = proc {
            raise unless respond_to?(:base)

            base == 2
          }

          {
            logic:,
            symbol: :must_be_base_2
          }
        end

        context "when allowed" do
          it "runs the command" do
            expect(response.status).to be(200)
            expect(response.headers).to be_a(Hash)
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
            expect(response.status).to be(403)
            expect(response.headers).to be_a(Hash)
            expect(JSON.parse(response.body).find { |e| e["key"] == "runtime.not_allowed" }["message"]).to eq(
              "Not allowed: Must be 1900 but was 2"
            )
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
            expect(response.status).to be(200)
            expect(response.headers).to be_a(Hash)
            expect(response.body).to eq("8")
          end

          describe "#manifest" do
            it "contains the errors for not allowed" do
              domain_manifest = command_connector.manifest[:global_organization][:global_domain]
              error_manifest = domain_manifest[:commands][:ComputeExponent][:error_types]

              expect(error_manifest.keys).to include("runtime.not_allowed")
            end
          end
        end

        context "when not allowed" do
          let(:allowed_rule) do
            :must_be_base_1900
          end

          it "fails with 401 and relevant error" do
            expect(command_connector.command_registry[ComputeExponent].command_class).to eq(ComputeExponent)

            expect(response.status).to be(403)
            expect(response.headers).to be_a(Hash)
            expect(JSON.parse(response.body).find { |e| e["key"] == "runtime.not_allowed" }["message"]).to eq(
              "Not allowed: Must be base 1900 but was 2"
            )
          end
        end
      end

      context "when declared with a proc" do
        context "without explanation" do
          let(:allowed_rule) do
            proc { base == 1900 }
          end

          it "fails with 401 and relevant error" do
            expect(response.status).to be(403)
            expect(response.headers).to be_a(Hash)
            expect(
              JSON.parse(response.body).find { |e| e["key"] == "runtime.not_allowed" }["message"]
            ).to match(/base == 1900/)
          end
        end
      end
    end

    context "when authentication required" do
      let(:requires_authentication) { true }

      describe "#manifest" do
        it "contains the errors for not allowed" do
          domain_manifest = command_connector.manifest[:global_organization][:global_domain]
          error_manifest = domain_manifest[:commands][:ComputeExponent][:error_types]

          expect(error_manifest.keys).to include("runtime.unauthenticated")
        end
      end

      context "when unauthenticated" do
        it "is 401" do
          expect(response.status).to be(401)
          expect(response.headers).to be_a(Hash)
          expect(JSON.parse(response.body)).to include { |e| e["key"] == "runtime.unauthenticated" }
        end
      end

      context "when authenticated" do
        let(:authenticator) do
          # normally we would return a user but we'll just generate a pointless integer
          # to test proxying to the request
          proc { path.length }
        end

        it "is 200" do
          expect(response.status).to be(200)
          expect(response.headers).to be_a(Hash)
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
                     ratings: [:integer],
                     junk: { type: :associative_array, value_type_declaration: :array }
          primary_key :id
        end
      end

      context "when user exists" do
        let(:user_id) do
          User.transaction do
            User.create(name: :whatever)
          end.id
        end

        let(:result_transformers) { [proc { |user| user.attributes }] }

        it "finds the user" do
          expect(response.status).to be(200)
          expect(response.headers).to be_a(Hash)
          expect(JSON.parse(response.body)).to eq("id" => user_id, "name" => "whatever")
        end

        context "when making options call" do
          let(:method) { "OPTIONS" }

          it "finds the user" do
            expect(response.status).to be(200)
            expect(response.headers).to be_a(Hash)
            expect(response.body).to eq("")
          end
        end
      end

      context "when not found error" do
        let(:user_id) { 100 }

        it "fails" do
          expect(response.status).to be(404)
          expect(response.headers).to be_a(Hash)

          errors = JSON.parse(response.body)

          expect(errors.size).to eq(1)
          expect(errors).to include { |e| e["key"] == "runtime.user_not_found" }
        end
      end

      context "with an association" do
        let(:point_class) do
          stub_class = ->(klass) { stub_const(klass.name, klass) }

          Class.new(Foobara::Model) do
            class << self
              def name
                "Point"
              end
            end

            stub_class.call(self)

            attributes x: :integer, y: :integer
          end
        end

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
          User.attributes referral: referral_class, point: point_class
        end

        context "with AtomicSerializer" do
          let(:serializers) { described_class::Serializers::AtomicSerializer }

          context "when user exists with a referral" do
            let(:user) do
              User.transaction do
                referral = referral_class.create(email: "Some@email.com")
                User.create(name: "Some Name", referral:, ratings: [1, 2, 3], point: { x: 1, y: 2 })
              end
            end

            let(:user_id) { user.id }

            let(:referral_id) {  user.referral.id }

            it "serializes as an atom" do
              expect(response.status).to be(200)
              expect(response.headers).to be_a(Hash)
              expect(JSON.parse(response.body)).to eq(
                "id" => user_id,
                "name" => "Some Name",
                "referral" => referral_id,
                "ratings" => [1, 2, 3],
                "point" => { "x" => 1, "y" => 2 }
              )
            end
          end
        end

        context "with AggregateSerializer" do
          let(:serializers) { described_class::Serializers::AggregateSerializer }
          let(:pre_commit_transformers) { Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer }

          context "when user exists with a referral" do
            let(:command_class) do
              user_class
              referral_class

              stub_class = ->(klass) { stub_const(klass.name, klass) }

              Class.new(Foobara::Command) do
                class << self
                  def name
                    "QueryUser"
                  end
                end

                stub_class.call(self)

                inputs user: User
                result stuff: [User, Referral]

                load_all

                def execute
                  {
                    stuff: [user, user.referral]
                  }
                end
              end
            end

            let(:user) do
              User.transaction do
                referral = referral_class.create(email: "Some@email.com")
                User.create(
                  name: "Some Name",
                  referral:,
                  ratings: [1, 2, 3],
                  point: { x: 1, y: 2 },
                  junk: { [1, 2, 3] => [1, 2, 3] }
                )
              end
            end

            let(:user_id) { user.id }
            let(:referral_id) {  user.referral.id }

            it "serializes as an aggregate" do
              expect(response.status).to be(200)
              expect(response.headers).to be_a(Hash)
              expect(JSON.parse(response.body)).to eq(
                "stuff" => [
                  {
                    "id" => 1,
                    # TODO: This is kind of crazy that we can only have strings as keys. Should raise exception.
                    "junk" => { "[1, 2, 3]" => [1, 2, 3] },
                    "name" => "Some Name",
                    "point" => { "x" => 1, "y" => 2 },
                    "ratings" => [1, 2, 3],
                    "referral" => { "email" => "some@email.com", "id" => 1 }
                  },
                  {
                    "email" => "some@email.com", "id" => 1
                  }
                ]
              )
            end

            it "contains pre_commit_transformers in its manifest" do
              command_manifest = command_connector.manifest[:global_organization][:global_domain][:commands][:QueryUser]
              manifest = command_manifest[:pre_commit_transformers].find { |h|
                h[:name] == "Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer"
              }
              expect(manifest).to be_a(Hash)
            end
          end
        end

        context "with RecordStoreSerializer" do
          let(:serializers) { described_class::Serializers::RecordStoreSerializer }
          let(:aggregate_entities) { true }

          context "when user exists with a referral" do
            let(:user) do
              User.transaction do
                referral = referral_class.create(email: "Some@email.com")
                User.create(name: "Some Name", referral:, ratings: [1, 2, 3], point: { x: 1, y: 2 })
              end
            end

            let(:user_id) { user.id }

            let(:referral_id) { user.referral.id }

            it "serializes as a record store" do
              expect(response.status).to be(200)
              expect(response.headers).to be_a(Hash)
              expect(JSON.parse(response.body)).to eq(
                "User" => {
                  "1" => {
                    "id" => 1,
                    "name" => "Some Name",
                    "referral" => 1,
                    "ratings" => [1, 2, 3],
                    "point" => { "x" => 1, "y" => 2 }
                  }
                },
                "Referral" => {
                  "1" => {
                    "id" => 1,
                    "email" => "some@email.com"
                  }
                }
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
        expect(response.status).to be(200)
        expect(response.headers).to be_a(Hash)
        expect(response.body).to eq("8")
      end
    end

    describe "#manifest" do
      context "when various transformers" do
        let(:query_string) { "bbaassee=#{base}" }

        let(:inputs_transformers) { [inputs_transformer] }
        let(:inputs_transformer) do
          Class.new(Foobara::TypeDeclarations::TypedTransformer) do
            class << self
              def input_type_declaration
                {
                  bbaassee: :string,
                  exponent: :string
                }
              end
            end

            def transform(inputs)
              {
                base: inputs["bbaassee"],
                exponent: inputs["exponent"]
              }
            end
          end
        end

        let(:result_transformers) { [result_transformer] }
        let(:result_transformer) do
          Class.new(Foobara::TypeDeclarations::TypedTransformer) do
            class << self
              def output_type_declaration
                { answer: :string }
              end
            end

            def transform(result)
              { answer: result.to_s }
            end
          end
        end

        it "runs the command" do
          expect(response.status).to be(200)
          expect(response.headers).to be_a(Hash)
          expect(JSON.parse(response.body)).to eq("answer" => "8")
        end

        describe "#manifest" do
          let(:manifest) { command_connector.manifest }

          it "uses types from the transformers" do
            h = manifest[:global_organization][:global_domain][:commands][:ComputeExponent]

            inputs_type = h[:inputs_type]
            result_type = h[:result_type]
            error_types = h[:error_types]

            expect(inputs_type).to eq(
              type: :attributes,
              element_type_declarations: {
                exponent: { type: :string },
                bbaassee: { type: :string }
              }
            )
            expect(result_type).to eq(
              type: :attributes,
              element_type_declarations: {
                answer: { type: :string }
              }
            )
            expect(error_types).to eq(
              "data.cannot_cast" => {
                category: :data,
                symbol: :cannot_cast,
                context_type_declaration: {
                  type: :attributes, element_type_declarations: {
                    cast_to: { type: :duck },
                    value: { type: :duck },
                    attribute_name: { type: :symbol }
                  }
                },
                is_fatal: true,
                path: [],
                runtime_path: []
              },
              "data.unexpected_attributes" => {
                category: :data,
                symbol: :unexpected_attributes,
                context_type_declaration: {
                  type: :attributes,
                  element_type_declarations: {
                    unexpected_attributes: { type: :array, element_type_declaration: { type: :symbol } },
                    allowed_attributes: { type: :array, element_type_declaration: { type: :symbol } }
                  }
                },
                is_fatal: true,
                path: [],
                runtime_path: []
              },
              "data.exponent.cannot_cast" => {
                category: :data,
                symbol: :cannot_cast,
                context_type_declaration: {
                  type: :attributes,
                  element_type_declarations: {
                    cast_to: { type: :duck },
                    value: { type: :duck },
                    attribute_name: { type: :symbol }
                  }
                },
                is_fatal: true,
                path: [:exponent],
                runtime_path: []
              },
              "data.bbaassee.cannot_cast" => {
                category: :data,
                symbol: :cannot_cast,
                context_type_declaration: {
                  type: :attributes,
                  element_type_declarations: {
                    cast_to: { type: :duck },
                    value: { type: :duck },
                    attribute_name: { type: :symbol }
                  }
                },
                is_fatal: true,
                path: [:bbaassee],
                runtime_path: []
              },
              "runtime.some_runtime" => {
                category: :runtime,
                context_type_declaration: { type: :duck },
                is_fatal: true,
                path: [],
                runtime_path: [],
                symbol: :some_runtime
              }
            )
          end
        end
      end
    end

    context "with describe path" do
      let(:path) { "/describe/ComputeExponent" }

      it "describes the command" do
        expect(response.status).to be(200)
        json = JSON.parse(response.body)
        expect(json["inputs_type"]["element_type_declarations"]["base"]["type"]).to eq("integer")
      end

      context "with describe path" do
        let(:path) { "/describe_command/ComputeExponent" }

        it "describes the command" do
          expect(response.status).to be(200)
          json = JSON.parse(response.body)
          expect(json["inputs_type"]["element_type_declarations"]["base"]["type"]).to eq("integer")
        end
      end
    end

    describe "connector manifest" do
      describe "#manifest" do
        let(:manifest) { command_connector.manifest }

        it "returns metadata about the commands" do
          expect(
            manifest[:global_organization][:global_domain][:commands][:ComputeExponent][:result_type]
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

          let(:serializers) {
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
              manifest[:global_organization][:global_domain][:types].keys
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

          context "with manifest path" do
            let(:query_string) { nil }
            let(:path) { "/manifest" }

            it "includes types" do
              expect(response.status).to be(200)
              json = JSON.parse(response.body)
              expect(json["global_organization"]["global_domain"]["types"].keys).to include("User")
            end
          end

          context "with describe_type path" do
            let(:query_string) { nil }
            let(:path) { "/describe_type/User" }

            it "includes types" do
              expect(response.status).to be(200)
              json = JSON.parse(response.body)
              expect(json["declaration_data"]["name"]).to eq("User")
            end
          end
        end
      end
    end
  end
end
