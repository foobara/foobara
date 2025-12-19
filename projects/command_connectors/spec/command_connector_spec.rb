RSpec.describe Foobara::CommandConnector do
  after do
    Foobara.reset_alls
  end

  let(:command_class) do
    sc = ->(*args, &block) { stub_class(*args, &block) }

    stub_class(:ComputeExponent, Foobara::Command) do
      error_klass = sc.call(:SomeRuntimeError, Foobara::RuntimeError) do
        context :duck
      end

      input_error_class = sc.call(:SomeInputError, Foobara::Value::DataError) do
        class << self
          def context_type_declaration
            :duck
          end
        end
      end

      possible_error error_klass
      possible_input_error :base, input_error_class

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
    described_class.new(authenticator:, default_serializers:, default_pre_commit_transformers:)
  end

  let(:command_registry) { command_connector.command_registry }

  let(:authenticator) { nil }
  let(:default_serializers) do
    [Foobara::CommandConnectors::Serializers::ErrorsSerializer,
     Foobara::CommandConnectors::Serializers::JsonSerializer]
  end
  let(:default_pre_commit_transformers) { nil }

  let(:base) { 2 }
  let(:exponent) { 3 }

  let(:response) { command_connector.run(full_command_name:, action:, inputs:) }
  let(:parsed_response) { JSON.parse(response.body) }

  let(:action) { "run" }
  let(:full_command_name) { "ComputeExponent" }
  let(:inputs) do
    {
      base:,
      exponent:
    }
  end
  let(:inputs_transformers) { nil }
  let(:result_transformers) { nil }
  let(:inputs_transformers_sugar) { nil }
  let(:result_transformers_sugar) { nil }
  let(:errors_transformers) { nil }
  let(:pre_commit_transformers) { nil }
  let(:serializers) { nil }
  let(:response_mutators) { nil }
  let(:request_mutators) { nil }
  let(:allowed_rule) { nil }
  let(:allowed_rules) { nil }
  let(:requires_authentication) { nil }
  let(:capture_unknown_error) { false }
  let(:aggregate_entities) { nil }
  let(:atomic_entities) { nil }

  describe "#connect" do
    context "when command is connected before it is loaded" do
      let(:command_class) do
        stub_module :SomeOrg do
          foobara_organization!
        end

        stub_module("SomeOrg::SomeDomain") do
          foobara_domain!
        end

        stub_class "SomeOrg::SomeDomain::SomeCommand", Foobara::Command do
          description "just some command"
        end
      end

      it "registers the command" do
        command_connector.connect("SomeOrg::SomeDomain::SomeCommand")

        command_class

        exposed_commands = command_connector.all_exposed_commands
        expect(exposed_commands.size).to eq(1)
        exposed_command = exposed_commands.first
        transformed_command = exposed_command.transformed_command_class

        expect(transformed_command.command_class).to eq(command_class)
        expect(transformed_command.new.inputs).to eq({})
      end
    end

    context "when command is in an organization" do
      let!(:org_module) do
        stub_module :SomeOrg do
          foobara_organization!
        end
      end

      let!(:domain_module) do
        stub_module("SomeOrg::SomeDomain") do
          foobara_domain!
        end
      end

      let!(:command_class) do
        stub_module "SomeOtherOrg" do
          foobara_organization!
        end
        stub_module "SomeOtherOrg::SomeOtherDomain" do
          foobara_domain!
        end
        stub_class "SomeOtherOrg::SomeOtherDomain::SomeOtherCommand", Foobara::Command do
          inputs email: :email
        end
        stub_class "SomeOrg::SomeDomain::SomeCommand", Foobara::Command do
          description "just some command"
          depends_on SomeOtherOrg::SomeOtherDomain::SomeOtherCommand
        end
      end

      it "registers the command" do
        command_connector.connect(org_module)

        expect(command_connector.command_connected?(SomeOrg::SomeDomain::SomeCommand)).to be true

        exposed_commands = command_connector.all_exposed_commands
        expect(exposed_commands.size).to eq(1)
        exposed_command = exposed_commands.first

        expect(exposed_command.full_command_symbol).to eq(:"some_org::some_domain::some_command")

        transformed_command = exposed_command.transformed_command_class
        expect(transformed_command.command_class).to eq(command_class)

        command_classes = []

        command_registry.each_transformed_command_class do |klass|
          command_classes << klass
        end

        expect(command_classes).to eq([transformed_command])
        expect(command_registry.all_transformed_command_classes).to eq([transformed_command])
      end

      context "when registering via domain" do
        before do
          command_connector.connect(domain_module)
        end

        it "registers the command" do
          transformed_commands = command_connector.all_transformed_command_classes
          expect(transformed_commands.size).to eq(1)
          expect(transformed_commands.first.command_class).to eq(command_class)
        end

        context "when generating a manifest" do
          it "includes the organization" do
            manifest = command_connector.foobara_manifest

            expect(manifest[:organization].keys).to contain_exactly(:SomeOrg, :global_organization)
            expect(manifest[:command][:"SomeOrg::SomeDomain::SomeCommand"][:description]).to eq("just some command")
          end
        end
      end
    end

    context "when connecting a command that returns sensitive data" do
      before do
        stub_module :SomeOrg do
          foobara_organization!
        end

        stub_module("SomeOrg::SomeDomain") do
          foobara_domain!
        end

        stub_class "SomeOrg::SomeDomain::User", Foobara::Entity do
          attributes do
            id :integer
            password :string, :allow_nil, :sensitive
            username :string, :required
            foo :array do
              bar :string, :sensitive, :allow_nil
              baz :string
            end
          end

          primary_key :id
        end

        stub_class "SomeOrg::SomeDomain::CreateUser", Foobara::Command do
          inputs do
            username :string, :required
            password :string, :sensitive
            foo :array do
              bar :string, :sensitive, :allow_nil
              baz :string
            end
          end

          result SomeOrg::SomeDomain::User

          def execute
            SomeOrg::SomeDomain::User.create(inputs)
          end
        end

        stub_class "SomeOrg::SomeDomain::Login", Foobara::Command do
          inputs do
            username :string, :required
            password :string, :required, :sensitive
          end

          result :string
        end
      end

      it "does not include sensitive input types in the manifest" do
        command_connector.connect(SomeOrg::SomeDomain::CreateUser)
        command_connector.connect(SomeOrg::SomeDomain::Login)

        manifest = command_connector.foobara_manifest

        user_manifest = manifest[:type][:"SomeOrg::SomeDomain::User"]
        declaration_data = user_manifest[:declaration_data]

        expect(
          declaration_data[:attributes_declaration][:element_type_declarations].keys
        ).to contain_exactly(:username, :id, :foo)
      end

      context "when running a command that returns sensitive values" do
        let(:full_command_name) { "SomeOrg::SomeDomain::CreateUser" }
        let(:inputs) do
          {
            username: "foo",
            password: "bar",
            foo: [{ bar: "bar", baz: "baz" }, { baz: "baz2" }]
          }
        end

        let(:serializers) { Foobara::CommandConnectors::Serializers::AggregateSerializer }
        let(:pre_commit_transformers) { Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer }

        before do
          Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
          command_connector.connect(SomeOrg::SomeDomain::CreateUser, serializers:, pre_commit_transformers:)
        end

        it "does not include sensitive output values in the result" do
          expect(response.status).to be(0)
          expect(response.error).to be_nil
          expect(JSON.parse(response.body)).to eq(
            "id" => 1,
            "username" => "foo",
            "foo" => [
              { "baz" => "baz" },
              { "baz" => "baz2" }
            ]
          )
        end

        context "when command can return a thunk" do
          let(:serializers) { [] }
          let(:full_command_name) { "SomeOrg::SomeDomain::FindUser" }
          let(:user) do
            SomeOrg::SomeDomain::CreateUser.run!(
              username: "foo",
              password: "bar",
              foo: [{ bar: "bar", baz: "baz" }, { baz: "baz2" }]
            )
          end
          let(:user_id) do
            user.id
          end
          let(:some_other_user) do
            SomeOrg::SomeDomain::CreateUser.run!(
              username: "baz",
              password: "baz",
              foo: [{ bar: "baz", baz: "baz" }, { baz: "baz" }]
            )
          end
          let(:inputs) do
            { user: user_id }
          end
          let(:pre_commit_transformers) { [] }

          before do
            some_other_user_id = some_other_user.id

            stub_class "SomeOrg::SomeDomain::FindUser", Foobara::Command do
              inputs do
                user SomeOrg::SomeDomain::User
              end

              result SomeOrg::SomeDomain::User

              define_method :execute do
                SomeOrg::SomeDomain::User.thunk(some_other_user_id)
              end
            end

            command_connector.connect(SomeOrg::SomeDomain::FindUser)
          end

          it "returns a thunk but in the command connector's namespace" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq(some_other_user.id)
          end
        end

        context "when nothing in the array needs to be changed" do
          let(:inputs) do
            {
              username: "foo",
              password: "bar",
              foo: [{ baz: "baz" }, { baz: "baz2" }]
            }
          end

          it "does not include sensitive output values in the result" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq(
              "id" => 1,
              "username" => "foo",
              "foo" => [
                { "baz" => "baz" },
                { "baz" => "baz2" }
              ]
            )
          end
        end

        context "when nothing in the record needs to be changed" do
          let(:inputs) do
            {
              username: "foo",
              foo: []
            }
          end

          it "does not include sensitive output values in the result" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq(
              "id" => 1,
              "username" => "foo",
              "foo" => []
            )
          end
        end

        context "when entity is a detached entity" do
          let(:full_command_name) { "BuildSomeDetachedEntity" }
          let(:inputs) do
            {
              id: 1,
              username: "foo",
              password: "bar",
              foo: [{ bar: "bar", baz: "baz" }, { baz: "baz2" }]
            }
          end

          before do
            stub_class "SomeDetachedEntity", Foobara::DetachedEntity do
              attributes do
                id :integer
                password :string, :allow_nil, :sensitive
                username :string, :required
                foo :array do
                  bar :string, :sensitive, :allow_nil
                  baz :string
                end
              end

              primary_key :id
            end

            stub_class "BuildSomeDetachedEntity", Foobara::Command do
              inputs do
                id :integer, :required
                username :string, :required
                password :string, :sensitive
                foo :array do
                  bar :string, :sensitive, :allow_nil
                  baz :string
                end
              end

              result SomeDetachedEntity

              def execute
                SomeDetachedEntity.new(inputs)
              end
            end

            command_connector.connect(BuildSomeDetachedEntity, serializers:, pre_commit_transformers:)
          end

          it "does not include sensitive output values in the result" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq(
              "id" => 1,
              "username" => "foo",
              "foo" => [
                { "baz" => "baz" },
                { "baz" => "baz2" }
              ]
            )
          end
        end
      end

      describe "#all_exposed_command_names" do
        it "includes all of the exposed command names" do
          command_connector.connect(SomeOrg::SomeDomain::CreateUser)
          expect(command_connector.all_exposed_command_names).to eq(["SomeOrg::SomeDomain::CreateUser"])
        end
      end

      describe "#all_exposed_type_names" do
        it "includes the entity names" do
          command_connector.connect(SomeOrg::SomeDomain::CreateUser)
          expect(command_connector.all_exposed_type_names).to include("SomeOrg::SomeDomain::User")
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
        inputs: inputs_transformers_sugar,
        result: result_transformers_sugar,
        inputs_transformers:,
        result_transformers:,
        errors_transformers:,
        serializers:,
        response: response_mutators,
        request: request_mutators,
        allowed_rule:,
        requires_authentication:,
        pre_commit_transformers:,
        capture_unknown_error:,
        aggregate_entities:,
        atomic_entities:,
        suffix:
      )
    end

    let(:suffix) { nil }

    it "runs the command" do
      expect(response.status).to be(0)
      expect(response.body).to eq("8")
    end

    context "with default transformers" do
      before do
        identity = proc { |x| x }

        command_connector.add_default_inputs_transformer(identity)
        command_connector.add_default_result_transformer(identity)
        command_connector.add_default_errors_transformer(identity)
        command_connector.add_default_pre_commit_transformer(identity)
      end

      it "runs the command" do
        expect(response.status).to be(0)
        expect(response.body).to eq("8")
      end
    end

    context "without serializers" do
      let(:default_serializers) { nil }
      # Setting a suffix guarantees it will be transformed
      let(:suffix) { "Whatever" }
      let(:full_command_name) { "ComputeExponentWhatever" }

      it "runs the command" do
        expect(response.status).to be(0)
        expect(response.body).to eq(8)
      end
    end

    context "when inputs are bad" do
      let(:inputs) { { some_bad_input: 10, exponent: } }

      let(:default_serializers) { Foobara::CommandConnectors::Serializers::JsonSerializer }
      let(:serializers) { Foobara::CommandConnectors::Serializers::ErrorsSerializer }

      it "fails" do
        expect(response.status).to be(1)

        error = JSON.parse(response.body).find { |e| e["key"] == "data.unexpected_attributes" }
        unexpected_attributes = error["context"]["unexpected_attributes"]

        expect(unexpected_attributes).to eq(["some_bad_input"])
      end
    end

    context "when command doesn't exist" do
      let(:full_command_name) { "DoesNotExist" }

      it "raises" do
        expect {
          response
        }.to raise_error(Foobara::CommandConnector::NoCommandFoundError)
      end
    end

    context "when unknown error" do
      let(:capture_unknown_error) { true }
      let(:default_serializers) do
        [
          Foobara::CommandConnectors::Serializers::ErrorsSerializer,
          Foobara::CommandConnectors::Serializers::JsonSerializer
        ]
      end

      before do
        command_class.define_method :execute do
          raise "kaboom!"
        end
      end

      it "fails" do
        expect(response.status).to be(1)

        error = JSON.parse(response.body).find { |e| e["key"] == "runtime.unknown" }

        expect(error["message"]).to eq("kaboom!")
        expect(error["is_fatal"]).to be(true)
      end

      context "when not capturing unknown errors when connecting the command" do
        let(:capture_unknown_error) { false }

        it "explodes" do
          expect { response }.to raise_error("kaboom!")
        end

        context "when capturing all unknown errors" do
          let(:command_connector) do
            described_class.new(authenticator:, default_serializers:, capture_unknown_error: true)
          end

          it "fails" do
            expect(response.status).to be(1)

            error = JSON.parse(response.body).find { |e| e["key"] == "runtime.unknown" }

            expect(error["message"]).to eq("kaboom!")
            expect(error["is_fatal"]).to be(true)
          end
        end
      end
    end

    context "with a response mutator" do
      let(:full_command_name) { "SomeCommand" }
      let(:response_mutators) { [response_mutator] }
      let(:response_mutator) { response_mutator_class }

      let(:command_class) do
        stub_class(:SomeCommand, Foobara::Command) do
          inputs value: :string
          result foo: :string, bar: :string

          def execute
            { foo: "foo #{value}", bar: "bar #{value}" }
          end
        end
      end

      let(:inputs) { { value: "some value" } }

      let(:response_mutator_class) do
        stub_class("ChangeBarToBazMutator", Foobara::CommandConnectors::ResponseMutator) do
          def result_type_declaration_from(result_type)
            new_declaration = Foobara::Util.deep_dup(result_type.declaration_data)
            element_type_declarations = new_declaration[:element_type_declarations]

            old_bar = element_type_declarations.delete(:bar)

            element_type_declarations[:baz] = old_bar

            new_declaration
          end

          def mutate(response)
            bar = response.body.delete(:bar)
            response.body[:baz] = bar
          end
        end
      end

      it "mutates the response and gives an expected mutated result type in the manifest" do
        manifest = command_connector.foobara_manifest

        expect(manifest[:command][:SomeCommand][:response_mutators]).to eq(["ChangeBarToBazMutator"])

        expect(manifest[:command][:SomeCommand][:result_type]).to eq(
          type: :attributes,
          element_type_declarations: {
            baz: :string,
            foo: :string
          }
        )
        expect(JSON.parse(response.body)).to eq("foo" => "foo some value", "baz" => "bar some value")
      end

      describe "#foobara_manifest" do
        context "when mutator is an instance" do
          let(:response_mutator) { response_mutator_class.new(true) }

          it "mutates the response and gives an expected mutated result type in the manifest" do
            manifest = command_connector.foobara_manifest
            expect(manifest[:command][:SomeCommand][:response_mutators]).to eq(["ChangeBarToBazMutator"])
          end

          context "when mutator is an anonymous instance" do
            let(:response_mutator_class) do
              Class.new(Foobara::CommandConnectors::ResponseMutator) do
                def result_type_declaration_from(result_type)
                  result_type
                end
              end
            end

            it "mutates the response and gives an expected mutated result type in the manifest" do
              manifest = command_connector.foobara_manifest
              expect(manifest[:command][:SomeCommand][:response_mutators].first).to be_a(String)
            end
          end
        end
      end

      context "with two mutators" do
        let(:response_mutators) { [response_mutator_class, another_mutator] }

        let(:another_mutator) do
          stub_class("RemoveFooMutator", Foobara::CommandConnectors::ResponseMutator) do
            def result_type_declaration_from(result_type)
              Foobara::TypeDeclarations::Attributes.reject(result_type.declaration_data, :foo)
            end

            def mutate(response)
              response.body.delete(:foo)
            end
          end
        end

        it "mutates the response and gives an expected mutated result type in the manifest" do
          manifest = command_connector.foobara_manifest

          expect(manifest[:command][:SomeCommand][:result_type]).to eq(
            type: :attributes,
            element_type_declarations: {
              baz: :string
            }
          )
          expect(JSON.parse(response.body)).to eq("baz" => "bar some value")
        end
      end
    end

    context "with a request mutator" do
      let(:full_command_name) { "SomeCommand" }
      let(:request_mutators) { [request_mutator_class] }

      let(:command_class) do
        stub_class(:SomeCommand, Foobara::Command) do
          inputs foo: :string, baz: :string
          result :duck

          def execute
            inputs
          end
        end
      end

      let(:inputs) { { foo: "foo some value", bar: "bar some value" } }

      let(:request_mutator_class) do
        stub_class("ChangeBarToBazMutator", Foobara::CommandConnectors::RequestMutator) do
          def inputs_type_declaration_from(inputs_type)
            new_declaration = Foobara::Util.deep_dup(inputs_type.declaration_data)
            element_type_declarations = new_declaration[:element_type_declarations]

            old_bar = element_type_declarations.delete(:baz)

            element_type_declarations[:bar] = old_bar

            new_declaration
          end

          def mutate(request)
            inputs = Foobara::Util.deep_dup(request.inputs)
            bar = inputs.delete(:bar)
            request.inputs = inputs.merge(baz: bar)
          end
        end
      end

      it "mutates the response and gives an expected mutated inputs type in the manifest" do
        manifest = command_connector.foobara_manifest

        expect(manifest[:command][:SomeCommand][:inputs_type]).to eq(
          type: :attributes,
          element_type_declarations: {
            bar: :string,
            foo: :string
          }
        )

        expect(JSON.parse(response.body)).to eq("foo" => "foo some value", "baz" => "bar some value")
      end

      context "with two mutators" do
        let(:request_mutators) { [request_mutator_class, another_mutator] }

        let(:another_mutator) do
          stub_class("RemoveFoo2Mutator", Foobara::CommandConnectors::RequestMutator) do
            def inputs_type_declaration_from(inputs_type)
              with_foo2 = Foobara::Domain.current.foobara_type_from_declaration(foo2: :integer)
              Foobara::TypeDeclarations::Attributes.merge(inputs_type.declaration_data, with_foo2.declaration_data)
            end

            def mutate(response)
              inputs = response.inputs.dup
              inputs.delete(:foo2)
              response.inputs = inputs
            end
          end
        end

        it "mutates the request and gives an expected mutated inputs type in the manifest" do
          manifest = Foobara::TypeDeclarations.with_manifest_context(include_processors: true) do
            command_connector.foobara_manifest
          end

          expect(manifest[:command][:SomeCommand][:inputs_type]).to eq(
            type: :attributes,
            element_type_declarations: {
              foo2: :integer,
              foo: :string,
              bar: :string
            }
          )

          expect(JSON.parse(response.body)).to eq("baz" => "bar some value", "foo" => "foo some value")
        end
      end
    end

    context "with various transformers" do
      let(:inputs) { { bbaassee: base, exponent: } }

      let(:inputs_transformers) { [inputs_transformer] }
      let(:inputs_transformer) do
        stub_class(:RandomTransformer, Foobara::Value::Transformer) do
          def transform(inputs)
            {
              base: inputs[:bbaassee],
              exponent: inputs[:exponent]
            }
          end
        end
      end

      let(:result_transformers) { [->(result) { result * 2 }] }
      let(:errors_transformers) { [->(errors) { errors }] }

      it "runs the command" do
        expect(response.status).to be(0)
        expect(response.body).to eq("16")
      end

      context "when error" do
        let(:inputs) { { foo: "bar", exponent: } }

        it "is not success" do
          expect(response.status).to be(1)
          expect(response.body).to include("cannot_cast")
        end
      end

      context "with multiple transformers" do
        let(:identity) { ->(x) { x } }

        let(:inputs_transformers) { [inputs_transformer] }
        let(:inputs_transformers_sugar) { identity }
        let(:result_transformers) { [->(result) { result * 2 }, identity] }
        let(:errors_transformers) { [identity, identity] }
        let(:pre_commit_transformers) { [identity, identity] }

        it "runs the command and has the expected inputs type" do
          expect(response.status).to be(0)
          expect(response.body).to eq("16")

          transformed_command = command_connector.transformed_command_from_name("ComputeExponent")
          expect(transformed_command.inputs_type.declaration_data).to eq(
            type: :attributes,
            element_type_declarations: {
              base: :integer,
              exponent: :integer
            }
          )
        end

        context "with a typed transformer" do
          let(:identity) do
            stub_class "IdentityTransformer", Foobara::TypeDeclarations::TypedTransformer do
              def from_type_declaration
                to_type
              end

              def transform(value)
                value
              end
            end
          end

          it "runs the command and has the expected inputs type" do
            expect(response.status).to be(0)
            expect(response.body).to eq("16")

            transformed_command = command_connector.transformed_command_from_name("ComputeExponent")
            expect(transformed_command.inputs_type.declaration_data).to eq(
              type: :attributes,
              element_type_declarations: {
                base: :integer,
                exponent: :integer
              }
            )
          end
        end

        context "when error" do
          let(:inputs) { { foo: "bar", exponent: } }

          it "is not success" do
            expect(response.status).to be(1)
            expect(response.body).to include("cannot_cast")
          end
        end
      end

      context "with transformer instance instead of class" do
        let(:inputs_transformers) { [inputs_transformer.instance] }

        it "runs the command" do
          expect(response.status).to be(0)
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
            expect(response.status).to be(0)
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
            expect(response.status).to be(1)
            expect(JSON.parse(response.body).find { |e|
              e["key"] == "runtime.not_allowed"
            }["message"]).to eq(
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
            expect(response.status).to be(0)
            expect(response.body).to eq("8")
          end

          describe "#manifest" do
            it "contains the errors for not allowed" do
              error_manifest = command_connector.foobara_manifest[:command][:ComputeExponent][:possible_errors]

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

            expect(response.status).to be(1)
            expect(JSON.parse(response.body).find { |e|
              e["key"] == "runtime.not_allowed"
            }["message"]).to eq(
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
          let(:authenticator) do
            # normally we would return a user but we'll just use junk
            proc { Object.new }
          end

          it "fails with 401 and relevant error" do
            expect(response.status).to be(1)
            expect(response.outcome).to_not be_success
            expect(
              JSON.parse(response.body).find { |e| e["key"] == "runtime.not_allowed" }["message"]
            ).to match(/not.?allowed/i)
          end

          describe "#foobara_manifest" do
            it "contains info about the authenticator" do
              manifest = command_connector.foobara_manifest
              expect(manifest[:command][:ComputeExponent][:authenticator]).to eq(
                symbol: :authenticator,
                explanation: :authenticator
              )
            end
          end
        end
      end

      context "when authentication required" do
        let(:requires_authentication) { true }
        let(:authenticator) do
          proc {}
        end

        describe "#manifest" do
          it "contains the errors for not allowed" do
            error_manifest = command_connector.foobara_manifest[:command][:ComputeExponent][:possible_errors]

            expect(error_manifest.keys).to include("runtime.unauthenticated")
          end
        end

        context "when unauthenticated" do
          it "is 1" do
            expect(response.status).to be(1)
            expect(JSON.parse(response.body).map { |e| e["key"] }).to include("runtime.unauthenticated")
          end
        end

        context "when authenticated" do
          let(:authenticator) do
            # normally we would return a user but we'll just generate a pointless integer
            # to test proxying to the request
            proc { full_command_name.length }
          end

          let(:default_serializers) do
            [Foobara::CommandConnectors::Serializers::JsonSerializer]
          end

          it "is 200" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq(8)
          end
        end
      end

      context "with an entity input" do
        before do
          Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
        end

        let(:default_pre_commit_transformers) do
          [
            Foobara::CommandConnectors::Transformers::LoadAtomsPreCommitTransformer
          ]
        end

        let(:command_class) do
          user_class

          stub_class(:QueryUser, Foobara::Command) do
            inputs user: User
            result :User

            load_all

            def execute
              user
            end
          end
        end

        let(:full_command_name) { "QueryUser" }
        let(:inputs) { { user: user_id } }

        let(:user_class) do
          stub_class(:User, Foobara::Entity) do
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

          let(:result_transformers) { [proc(&:attributes)] }

          it "finds the user" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq("id" => user_id, "name" => "whatever")
          end
        end

        context "when not found error" do
          let(:user_id) { 100 }

          it "fails" do
            expect(response.status).to be(1)

            errors = JSON.parse(response.body)

            expect(errors.size).to eq(1)
            expect(errors.map { |e| e["key"] }).to include("runtime.user_not_found")
          end
        end

        context "with an association" do
          let(:point_class) do
            stub_class :Point, Foobara::Model do
              attributes x: :integer, y: :integer
            end
          end

          let(:referral_class) do
            stub_class(:Referral, Foobara::Entity) do
              attributes id: :integer, email: :email
              primary_key :id
            end
          end

          before do
            User.attributes referral: referral_class, point: point_class
          end

          context "with atomic_entities: true" do
            let(:atomic_entities) { true }

            it "includes the AtomicSerializer" do
              command_manifest = command_connector.foobara_manifest[:command][:QueryUser]
              expect(
                command_manifest[:serializers]
              ).to include("Foobara::CommandConnectors::Serializers::AtomicSerializer")
            end
          end

          context "with AtomicSerializer" do
            let(:serializers) { Foobara::CommandConnectors::Serializers::AtomicSerializer }

            context "when user exists with a referral" do
              let(:user) do
                User.transaction do
                  referral = referral_class.create(email: "Some@email.com")
                  User.create(name: "Some Name", referral:, ratings: [1, 2, 3], point: { x: 1, y: 2 })
                end
              end

              let(:user_id) { user.id }

              let(:referral_id) { user.referral.id }

              it "serializes as an atom" do
                expect(response.status).to be(0)
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
            let(:serializers) { Foobara::CommandConnectors::Serializers::AggregateSerializer }
            let(:pre_commit_transformers) {
              Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer
            }

            context "when user exists with a referral" do
              let(:command_class) do
                user_class
                referral_class

                stub_class :QueryUser, Foobara::Command do
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
                expect(response.status).to be(0)
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
                command_manifest = Foobara::TypeDeclarations.with_manifest_context(include_processor: true) do
                  command_connector.foobara_manifest[:command][:QueryUser]
                end
                expect(command_manifest[:pre_commit_transformers]).to include(
                  "Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer"
                )
                expect(command_manifest[:serializers]).to include(
                  "Foobara::CommandConnectors::Serializers::AggregateSerializer"
                )
              end

              context "with aggregate serializer as default serializer" do
                let(:aggregate_entities) { nil }
                let(:pre_commit_transformers) { nil }
                let(:serializers) { nil }

                let(:default_serializers) do
                  [
                    Foobara::CommandConnectors::Serializers::AggregateSerializer,
                    Foobara::CommandConnectors::Serializers::ErrorsSerializer,
                    Foobara::CommandConnectors::Serializers::JsonSerializer
                  ]
                end

                let(:default_pre_commit_transformers) do
                  Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer
                end

                it "contains pre_commit_transformers in its manifest" do
                  command_manifest = command_connector.foobara_manifest[:command][:QueryUser]
                  expect(command_manifest[:pre_commit_transformers]).to include(
                    "Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer"
                  )
                  expect(command_manifest[:serializers]).to include(
                    "Foobara::CommandConnectors::Serializers::AggregateSerializer"
                  )
                end

                context "when disabled via aggregate_entities: false" do
                  let(:aggregate_entities) { false }

                  it "does not contain pre_commit_transformers in its manifest" do
                    command_manifest = command_connector.foobara_manifest[:command][:QueryUser]
                    expect(command_manifest[:pre_commit_transformers]).to be_nil

                    expect(
                      command_manifest[:serializers]
                    ).to_not include("CommandConnectors::Serializers::AggregateSerializer")
                  end
                end
              end
            end
          end

          context "with RecordStoreSerializer" do
            let(:serializers) { Foobara::CommandConnectors::Serializers::RecordStoreSerializer }
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
                expect(response.status).to be(0)
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

      describe "#manifest" do
        context "when various transformers" do
          let(:inputs) { { bbaassee: base, exponent: } }

          let(:inputs_transformers) { [inputs_transformer] }
          let(:inputs_transformer) do
            stub_class "SomeTransformer", Foobara::TypeDeclarations::TypedTransformer do
              def from_type_declaration
                {
                  bbaassee: :string,
                  exponent: :string
                }
              end

              def transform(inputs)
                {
                  base: inputs[:bbaassee],
                  exponent: inputs[:exponent]
                }
              end
            end
          end

          let(:result_transformers) { [result_transformer] }
          let(:result_transformer) do
            stub_class :SomeOtherTransformer, Foobara::TypeDeclarations::TypedTransformer do
              to(answer: :string)

              def transform(result)
                { answer: result.to_s }
              end
            end
          end

          it "runs the command" do
            expect(response.status).to be(0)
            expect(response.command.raw_inputs).to eq(bbaassee: 2, exponent: 3)
            expect(JSON.parse(response.body)).to eq("answer" => "8")
          end

          context "with bad inputs" do
            let(:inputs_transformer) do
              stub_class "SomeTransformer", Foobara::TypeDeclarations::TypedTransformer do
                def from_type_declaration
                  Foobara::Domain.current.foobara_type_from_declaration do
                    bbaassee :string, :required
                    exponent :string, :required
                  end
                end
              end
            end

            let(:inputs) { { exponent: } }

            it "is not success" do
              expect(response.status).to be(1)
            end
          end

          describe "#manifest" do
            let(:manifest) do
              Foobara::TypeDeclarations.with_manifest_context(include_processors: true) do
                command_connector.foobara_manifest
              end
            end

            it "uses types from the transformers" do
              h = manifest[:command][:ComputeExponent]

              inputs_type = h[:inputs_type]
              result_type = h[:result_type]
              error_types = h[:possible_errors]

              expect(inputs_type).to eq(
                type: :attributes,
                element_type_declarations: {
                  exponent: :string,
                  bbaassee: :string
                }
              )
              expect(result_type).to eq(
                type: :attributes,
                element_type_declarations: {
                  answer: :string
                }
              )
              expect(error_types).to eq(
                "runtime.some_runtime" => {
                  category: :runtime,
                  symbol: :some_runtime,
                  key: "runtime.some_runtime",
                  error: "SomeRuntimeError"
                },
                "data.base.some_input" => {
                  path: [:base],
                  category: :data,
                  symbol: :some_input,
                  key: "data.base.some_input",
                  error: "SomeInputError",
                  manually_added: true
                },
                "data.cannot_cast" => {
                  category: :data,
                  symbol: :cannot_cast,
                  key: "data.cannot_cast",
                  error: "Foobara::Value::Processor::Casting::CannotCastError",
                  processor_class: "Foobara::Value::Processor::Casting",
                  processor_manifest_data: {
                    casting: { cast_to: { type: :attributes,
                                          element_type_declarations: {
                                            bbaassee: :string, exponent:  :string
                                          } } }
                  }
                },
                "data.unexpected_attributes" => {
                  category: :data,
                  symbol: :unexpected_attributes,
                  key: "data.unexpected_attributes",
                  error: "attributes::SupportedProcessors::ElementTypeDeclarations::UnexpectedAttributesError",
                  processor_class: "attributes::SupportedProcessors::ElementTypeDeclarations",
                  processor_manifest_data: { element_type_declarations: { bbaassee: :string,
                                                                          exponent: :string } }
                },
                "data.bbaassee.cannot_cast" => {
                  path: [:bbaassee],
                  category: :data,
                  symbol: :cannot_cast,
                  key: "data.bbaassee.cannot_cast",
                  error: "Foobara::Value::Processor::Casting::CannotCastError",
                  processor_manifest_data: { casting: { cast_to: :string } }
                },
                "data.exponent.cannot_cast" => {
                  path: [:exponent],
                  category: :data,
                  symbol: :cannot_cast,
                  key: "data.exponent.cannot_cast",
                  error: "Foobara::Value::Processor::Casting::CannotCastError",
                  processor_manifest_data: { casting: { cast_to: :string } }
                }
              )
            end
          end

          describe "#possible_errors" do
            it "contains paths matching the transformed inputs" do
              transformed_command = command_connector.transformed_command_from_name("ComputeExponent")
              expect(transformed_command.possible_errors.map(&:key).map(&:to_s)).to contain_exactly(
                "runtime.some_runtime",
                "data.base.some_input",
                "data.cannot_cast",
                "data.unexpected_attributes",
                "data.bbaassee.cannot_cast",
                "data.exponent.cannot_cast"
              )
            end
          end
        end
      end

      context "with describe path" do
        let(:action) { "describe" }
        let(:full_command_name) { "ComputeExponent" }
        let(:inputs) { {} }

        it "describes the command" do
          expect(response.status).to be(0)
          json = JSON.parse(response.body)
          expect(json["inputs_type"]["element_type_declarations"]["base"]).to eq("integer")
        end

        context "with describe path" do
          let(:action) { "describe_command" }
          let(:full_command_name) { "ComputeExponent" }

          it "describes the command" do
            expect(response.status).to be(0)
            json = JSON.parse(response.body)
            expect(json["inputs_type"]["element_type_declarations"]["base"]).to eq("integer")
          end
        end
      end

      context "with help path" do
        let(:org_module) do
          stub_module :SomeOrg do
            foobara_organization!
          end
        end
        let(:action) { "help" }

        let(:domain_module) do
          org_module
          stub_module("SomeOrg::SomeDomain") do
            foobara_domain!
          end
        end

        let(:another_command_class) do
          domain_module
          stub_module "SomeOtherOrg" do
            foobara_organization!
          end
          stub_module "SomeOtherOrg::SomeOtherDomain" do
            foobara_domain!
          end
          stub_class "SomeOtherOrg::SomeOtherDomain::SomeOtherCommand", Foobara::Command do
            inputs email: :email
          end
          stub_class "SomeOrg::SomeDomain::SomeCommand", Foobara::Command do
            description "just some command"
            depends_on SomeOtherOrg::SomeOtherDomain::SomeOtherCommand
          end
        end

        before do
          command_connector.connect(another_command_class)

          stub_class("Foobara::CommandConnector::Commands::Help", Foobara::Command) do
            inputs request: Foobara::CommandConnector::Request
            result :string

            def execute
              "HELP!!!"
            end
          end
        end

        it "gives some help" do
          expect(response.status).to be(0)
          expect(response.body).to match(/HELP!!!/)
        end

        context "when asking for help with a specific element" do
          let(:action) { "help" }
          let(:full_command_name) { "ComputeExponent" }

          it "gives some help" do
            expect(response.status).to be(0)
            expect(response.body).to match(/HELP!!!/)
          end
        end

        context "when it is something accessible through GlobalOrganization but not the connector" do
          before do
            command_connector.connect(new_command)

            stub_class("Foobara::CommandConnector::Commands::Help", Foobara::Command) do
              inputs request: Foobara::CommandConnector::Request
              result :string

              def execute
                "HELP!!!"
              end
            end
          end

          let(:new_command) do
            stub_class(:NewCommand, Foobara::Command) do
              inputs do
                count :integer, min: 0
                log [:string]
              end
            end
          end

          context "when command" do
            let(:action) { "help" }
            let(:full_command_name) { "NewCommand" }

            it "gives some help" do
              expect(response.status).to be(0)
              expect(response.body).to match("HELP!!!")
            end
          end
        end
      end

      context "when the command returns a model from a domain it depends on (bad form but let's support it for now)" do
        let(:command_class) do
          user_class

          stub_module("DomainA") do
            foobara_domain!
          end
          stub_class("DomainA::MakeUser", Foobara::Command) do
            result DomainB::User
          end
        end

        let(:full_command_name) { "DomainA::MakeUser" }

        let(:user_class) do
          stub_module("DomainB") do
            foobara_domain!
          end

          stub_class("DomainB::User", Foobara::Model) do
            attributes name: :string
          end
        end

        it "includes the model and its domain in the manifest" do
          manifest = command_connector.foobara_manifest

          expect(manifest[:domain].keys).to include(:DomainB)
          expect(manifest[:type].keys).to include(:"DomainB::User")
        end
      end

      context "when command returns a model that has sensitive attributes nested within it" do
        before do
          Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
        end

        let(:default_serializers) do
          [
            Foobara::CommandConnectors::Serializers::AggregateSerializer,
            Foobara::CommandConnectors::Serializers::ErrorsSerializer,
            Foobara::CommandConnectors::Serializers::JsonSerializer
          ]
        end
        # TODO: make this automatic if AggregateSerializer is being used
        let(:pre_commit_transformers) { Foobara::CommandConnectors::Transformers::LoadAggregatesPreCommitTransformer }

        let(:command_class) do
          user_class

          stub_class(:QueryUser, Foobara::Command) do
            inputs user: User
            result :User

            load_all

            def execute
              user
            end
          end
        end

        let(:full_command_name) { "QueryUser" }
        let(:inputs) { { user: user_id } }

        let(:user_class) do
          rating_class
          stub_class(:User, Foobara::Entity) do
            attributes do
              id :integer
              name :string
              ssn :string, :sensitive
              ratings [:Rating]
            end

            primary_key :id
          end
        end

        let(:rating_class) do
          stub_class(:Rating, Foobara::Entity) do
            attributes do
              id :integer
              rating :integer
              secret :string, :sensitive
            end

            primary_key :id
          end
        end

        context "when user exists with a rating" do
          let(:user_id) do
            User.transaction do
              User.create(name: :whatever, ssn: "ssn", ratings: [Rating.create(rating: 1, secret: "secret")])
            end.id
          end

          it "finds the user" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq(
              "id" => 1,
              "name" => "whatever",
              "ratings" => [{
                "id" => 1,
                "rating" => 1
              }]
            )
          end
        end
      end

      context "when command returns an entity that has delegated attributes" do
        before do
          Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
        end

        let(:default_serializers) do
          [
            Foobara::CommandConnectors::Serializers::ErrorsSerializer,
            Foobara::CommandConnectors::Serializers::AtomicSerializer,
            Foobara::CommandConnectors::Serializers::JsonSerializer
          ]
        end

        # TODO: make this a default based on a flag
        let(:pre_commit_transformers) do
          Foobara::CommandConnectors::Transformers::LoadDelegatedAttributesEntitiesPreCommitTransformer
        end

        let(:command_class) do
          user_class

          stub_class(:CreateUser, Foobara::Command) do
            inputs User.attributes_for_create
            result :User

            def execute
              User.create(inputs)
            end
          end

          stub_class(:QueryUser, Foobara::Command) do
            inputs do
              stuff do
                things :array do
                  auth_user AuthUser, :required
                end
              end
            end

            result do
              stuff2 do
                things2 :array do
                  user User, :required
                end
              end
            end

            load_all

            def execute
              user = User.that_owns(stuff[:things][0][:auth_user])
              { stuff2: { things2: [{ user: }] } }
            end
          end
        end

        let(:full_command_name) { "QueryUser" }
        let(:inputs) do
          {
            stuff: {
              things: [{ auth_user: auth_user_id }]
            }
          }
        end

        let(:user_class) do
          auth_user_class
          stub_class(:User, Foobara::Entity) do
            attributes do
              id :integer
              name :string
              ssn :string, :sensitive
              ssn2 :string, :private
              foo :string
              stuff :private do
                things :array do
                  auth_user AuthUser, :required
                end
              end
            end

            primary_key :id
            delegate_attribute :username, [:stuff, :things, :"0", :auth_user, :username]
          end
        end

        let(:auth_user_class) do
          stub_class(:AuthUser, Foobara::Entity) do
            attributes do
              id :integer
              username :string
            end

            primary_key :id
          end
        end

        context "when user exists" do
          let(:user_id) do
            CreateUser.run!(
              name: :whatever,
              ssn: "123",
              ssn2: "789",
              foo: "bar",
              stuff: {
                things: [
                  { auth_user: auth_user_id }
                ]
              }
            ).id
          end

          let(:username) { "some_username" }
          let(:auth_user_id) do
            AuthUser.transaction do
              AuthUser.create(username:)
            end.id
          end

          before do
            user_id
          end

          it "finds the user and includes delegated attributes" do
            expect(response.status).to be(0)
            expect(JSON.parse(response.body)).to eq(
              "stuff2" => {
                "things2" => [
                  "user" => {
                    "id" => user_id,
                    "name" => "whatever",
                    "foo" => "bar",
                    "username" => "some_username"
                  }
                ]
              }
            )
          end

          context "with a simple entity return type" do
            let(:command_class) do
              user_class

              stub_class(:CreateUser, Foobara::Command) do
                inputs User.attributes_for_create
                result :User

                def execute
                  User.create(inputs)
                end
              end

              stub_class(:QueryUser, Foobara::Command) do
                inputs do
                  stuff do
                    things :array do
                      auth_user AuthUser, :required
                    end
                  end
                end

                result User

                load_all

                def execute
                  User.that_owns(stuff[:things][0][:auth_user])
                end
              end
            end

            it "responds with attributes that include the delegated attributes" do
              expect(response.status).to be(0)
              expect(JSON.parse(response.body)).to eq(
                "id" => 1,
                "name" => "whatever",
                "username" => "some_username",
                "foo" => "bar"
              )
            end
          end
        end
      end

      describe "connector manifest" do
        describe "#manifest" do
          let(:manifest) { command_connector.foobara_manifest }

          it "returns metadata about the commands" do
            expect(
              manifest[:command][:ComputeExponent][:result_type]
            ).to eq(:integer)
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

              stub_class :QueryUser, Foobara::Command do
                description "Queries a user"
                inputs user: User.entity_type
                result :User
              end
            end

            let(:full_command_name) { "QueryUser" }
            let(:inputs) { { user: user_id } }

            let(:serializers) {
              [proc(&:attributes)]
            }

            let(:user_class) do
              stub_class :User, Foobara::Entity do
                attributes id: :integer, name: :string
                primary_key :id
              end
            end

            it "returns metadata about the types referenced in the commands" do
              expect(
                manifest[:type].keys
              ).to contain_exactly(:User, :array, :associative_array, :atomic_duck, :attributes, :detached_entity,
                                   :duck, :duckture, :entity, :integer, :model, :number, :string, :symbol)
            end

            context "with manifest path" do
              let(:inputs) { {} }
              let(:action) { "manifest" }

              it "includes types" do
                expect(response.status).to be(0)
                json = JSON.parse(response.body)
                expect(json["type"].keys).to include("User")
              end
            end

            context "with list path" do
              let(:inputs) { {} }
              let(:action) { "list" }

              it "lists commands" do
                expect(response.status).to be(0)
                json = JSON.parse(response.body)

                expect(json).to eq([["QueryUser", nil]])
              end

              context "when verbose" do
                # TODO: would be nice to not have to do =true here...
                let(:inputs) { { verbose: true } }

                it "lists commands" do
                  expect(response.status).to be(0)
                  json = JSON.parse(response.body)

                  expect(json).to eq([["QueryUser", "Queries a user"]])
                end
              end
            end

            context "with describe_type path" do
              let(:inputs) { {} }
              let(:full_command_name) { "User" }
              let(:action) { "describe_type" }

              it "includes types" do
                expect(response.status).to be(0)
                json = JSON.parse(response.body)
                expect(json["declaration_data"]["name"]).to eq("User")
              end
            end
          end
        end
      end
    end

    describe "#patch_up_broken_parents_for_errors_with_missing_command_parents" do
      let(:fixture_path) {
        "#{__dir__}/fixtures/command_connectors/manifest_with_errors_with_missing_command_parents.yaml"
      }
      let(:manifest_hash) do
        YAML.load_file(fixture_path, aliases: true)
      end

      it "fixes busted parents by leapfrogging them and patching up scoped paths/names" do
        error_manifest = manifest_hash[:error][:"Foobara::Auth::FindUser::UserNotFoundError"]

        expect(error_manifest[:scoped_path]).to eq(["UserNotFoundError"])
        expect(error_manifest[:parent]).to eq([:command, "Foobara::Auth::FindUser"])
        expect(error_manifest[:scoped_prefix]).to be_nil
        expect(error_manifest[:scoped_name]).to eq("UserNotFoundError")

        # TODO: figure out how to set up this situation instead of directly passing a manifest
        # hash to a private method
        patched_up_manifest = command_connector.send(
          :patch_up_broken_parents_for_errors_with_missing_command_parents,
          manifest_hash
        )

        patched_up_error_manifest = patched_up_manifest[:error][:"Foobara::Auth::FindUser::UserNotFoundError"]

        expect(patched_up_error_manifest[:scoped_path]).to eq(["FindUser", "UserNotFoundError"])
        expect(patched_up_error_manifest[:parent]).to eq([:domain, "Foobara::Auth"])
        expect(patched_up_error_manifest[:scoped_prefix]).to eq(["FindUser"])
        expect(patched_up_error_manifest[:scoped_name]).to eq("FindUser::UserNotFoundError")
      end
    end

    context "with multiple layers of inheritance with allowed_rule entries" do
      let(:allowed_rule_a) do
        proc { "a" }
      end
      # intentionally skipping b
      let(:allowed_rule_c) do
        proc {} # will not be allowed
      end
      let(:allowed_rule_d) do
        proc { "d" }
      end

      let(:command_connector_class_a) do
        rule = allowed_rule_a
        stub_class "CommandConnectorA", described_class do
          register_allowed_rule :a, rule
        end
      end

      let(:command_connector_class_b) do
        stub_class "CommandConnectorB", command_connector_class_a
      end

      let(:command_connector_class_c) do
        rule = allowed_rule_c
        stub_class "CommandConnectorC", command_connector_class_b do
          register_allowed_rule :c, rule
        end
      end

      let(:command_connector_class_d) do
        rule = allowed_rule_d
        stub_class "CommandConnectorD", command_connector_class_c do
          register_allowed_rule :d, rule
        end
      end
      let(:command_connector) { command_connector_class_d.new }

      it "puts the expected allowed rules on the command connector" do
        command_connector.connect(command_class, suffix: "A", allow_if: :a)
        command_connector.connect(command_class, suffix: "B")
        command_connector.connect(command_class, suffix: "C", allowed_rule: :c)
        command_connector.connect(command_class, suffix: "D", allowed_rule: :d)

        response = command_connector.run(full_command_name: "ComputeExponentA", action:, inputs:)
        expect(response.status).to be(0)
        expect(response.command.allowed_rule.symbol).to be(:a)

        response = command_connector.run(full_command_name: "ComputeExponentB", action:, inputs:)
        expect(response.status).to be(0)
        expect(response.command.allowed_rule).to be_nil

        response = command_connector.run(full_command_name: "ComputeExponentC", action:, inputs:)
        expect(response.status).to be(1)
        expect(response.command.allowed_rule.symbol).to be(:c)

        response = command_connector.run(full_command_name: "ComputeExponentD", action:, inputs:)
        expect(response.status).to be(0)
        expect(response.command.allowed_rule.symbol).to be(:d)
      end
    end

    context "with multiple authenticators to choose from" do
      let(:authenticator_a) do
        stub_class("NotApplicableAuthenticator", Foobara::CommandConnector::Authenticator) do
          def initialize
            super(symbol: :a, &proc { "a" })
          end

          def applicable?(_request)
            false
          end
        end
      end

      let(:authenticator_b) do
        stub_class("ApplicableAuthenticator", Foobara::CommandConnector::Authenticator) do
          def initialize
            super(symbol: :b, &proc { "b" })
          end
        end
      end

      let(:authenticator) { [authenticator_a, authenticator_b] }
      let(:requires_authentication) { true }

      it "chooses the applicable authenticator" do
        expect(response.status).to be(0)
        expect(response.command.authenticated_user).to eq("b")
      end

      describe "#foobara_manifest" do
        it "contains combined info about the authenticator" do
          manifest = command_connector.foobara_manifest

          expect(manifest[:command][:ComputeExponent][:authenticator]).to eq(
            symbol: :a_or_b,
            explanation: "a, or b"
          )
        end
      end
    end

    context "with multiple layers of inheritance with authenticator entries" do
      let(:authenticator_a) do
        stub_class("SomeAuthenticator", Foobara::CommandConnector::Authenticator) do
          def initialize
            super(symbol: :a, &proc { ["a", "acred"] })
          end
        end
      end
      # intentionally skipping b
      let(:authenticator_c) do
        proc {} # will not be allowed
      end
      let(:authenticator_d) do
        proc { "d" }
      end
      let(:authenticator_e) do
        proc { "e" }
      end

      let(:command_connector_class_a) do
        authenticator = authenticator_a
        stub_class "CommandConnectorA", described_class do
          register_authenticator :a, authenticator
        end
      end

      let(:command_connector_class_b) do
        stub_class "CommandConnectorB", command_connector_class_a
      end

      let(:command_connector_class_c) do
        authenticator = authenticator_c
        stub_class "CommandConnectorC", command_connector_class_b do
          register_authenticator :c, authenticator
        end
      end

      let(:command_connector_class_d) do
        authenticator = authenticator_d
        stub_class "CommandConnectorD", command_connector_class_c do
          register_authenticator :d, authenticator
        end
      end

      let(:command_connector_class_e) do
        stub_class "CommandConnectorE", command_connector_class_d
      end

      let(:command_connector_a) { command_connector_class_a.new(authenticator: authenticator_a) }
      let(:command_connector_b) { command_connector_class_b.new(authenticator: "a") }
      let(:command_connector_c) { command_connector_class_c.new(authenticator: :a) }
      let(:command_connector_d) { command_connector_class_d.new(authenticator: :c) }
      let(:command_connector_e) { command_connector_class_e.new(authenticator: :d) }

      it "puts the expected allowed rules on the command connector" do
        command_connector_a.connect(command_class, :requires_authentication)
        command_connector_b.connect(command_class, :auth)
        command_connector_c.connect(command_class, requires_authentication: true)
        command_connector_d.connect(command_class, requires_authentication: true)
        command_connector_e.connect(command_class, requires_authentication: true, authenticator: [authenticator_e])

        response = command_connector_a.run(full_command_name:, action:, inputs:)
        expect(response.status).to be(0)
        expect(response.command.authenticated_user).to eq("a")
        expect(response.command.authenticator.symbol).to be(:a)

        response = command_connector_b.run(full_command_name:, action:, inputs:)
        expect(response.status).to be(0)
        expect(response.command.authenticated_user).to eq("a")
        expect(response.command.authenticated_credential).to eq("acred")
        expect(response.command.authenticator.symbol).to be(:a)

        response = command_connector_c.run(full_command_name:, action:, inputs:)
        expect(response.status).to be(0)
        expect(response.command.authenticated_user).to eq("a")
        expect(response.command.authenticator.symbol).to be(:a)

        response = command_connector_d.run(full_command_name:, action:, inputs:)
        expect(response.status).to be(1)
        expect(response.error.key).to eq("runtime.unauthenticated")
        expect(response.command.authenticated_user).to be_nil
        expect(response.command.authenticator.symbol).to be(:c)

        response = command_connector_e.run(full_command_name:, action:, inputs:)
        expect(response.status).to be(0)
        expect(response.command.authenticated_user).to eq("e")
      end

      describe "#foobara_manifest" do
        it "contains info about the authenticator" do
          command_connector_a.connect(command_class, requires_authentication: true)
          manifest = command_connector_a.foobara_manifest
          expect(manifest[:command][:ComputeExponent][:authenticator]).to eq(
            symbol: :a,
            explanation: :a
          )
        end
      end
    end

    context "when using sugar" do
      let(:command_class) do
        stub_class("SomeCommand", Foobara::Command) do
          inputs do
            foo :string, default: "defaultfoo"
            bar :string, default: "defaultbar"
            baz :string, default: "defaultbaz"
          end
          result do
            foo :string
            bar :string
            baz :string
          end

          def execute
            inputs
          end
        end
      end
      let(:full_command_name) { command_class.full_command_name }

      context "when only" do
        context "with non-array" do
          let(:inputs_transformers_sugar) do
            { only: :foo }
          end
          let(:result_transformers_sugar) do
            { only: :bar }
          end

          let(:inputs) do
            { foo: "foo" }
          end

          it "can add/remove inputs/results" do
            expect(response.status).to be(0)
            expect(parsed_response).to eq("bar" => "defaultbar")
          end
        end

        context "when arrays" do
          let(:inputs_transformers_sugar) do
            { only: [:foo, :bar] }
          end
          let(:result_transformers_sugar) do
            { only: [:bar, :baz] }
          end
          let(:inputs) do
            {
              foo: "foo",
              bar: "bar"
            }
          end

          it "can add/remove inputs/results" do
            expect(response.status).to be(0)
            expect(parsed_response).to eq("bar" => "bar", "baz" => "defaultbaz")
          end
        end
      end

      context "when reject" do
        context "with non-array" do
          let(:inputs_transformers_sugar) do
            { reject: :foo }
          end
          let(:result_transformers_sugar) do
            { reject: :bar }
          end

          let(:inputs) do
            {
              bar: "bar",
              baz: "baz"
            }
          end

          it "can add/remove inputs/results" do
            expect(response.status).to be(0)
            expect(parsed_response).to eq("foo" => "defaultfoo", "baz" => "baz")
          end
        end

        context "when arrays" do
          let(:inputs_transformers_sugar) do
            { reject: [:foo, :bar] }
          end
          let(:result_transformers_sugar) do
            { reject: [:bar, :baz] }
          end
          let(:inputs) do
            { baz: "baz" }
          end

          it "can add/remove inputs/results" do
            expect(response.status).to be(0)
            expect(parsed_response).to eq("foo" => "defaultfoo")
          end
        end
      end

      context "when set" do
        context "with non-array" do
          let(:inputs_transformers_sugar) do
            { set: { foo: -> { "setfoo" } } }
          end

          let(:inputs) do
            {
              bar: "bar",
              baz: "baz"
            }
          end

          it "can add/remove inputs/results" do
            expect(response.status).to be(0)
            expect(parsed_response).to eq("foo" => "setfoo", "baz" => "baz", "bar" => "bar")
          end
        end
      end

      context "when mixture of sugar and non sugar transformers" do
        let(:inputs_transformers_sugar) do
          [
            Foobara::AttributesTransformers.only(:bar, :baz),
            { only: [:bar] }
          ]
        end
        let(:result_transformers_sugar) do
          { only: [:bar, :baz] }
        end
        let(:inputs) do
          {
            bar: "bar"
          }
        end

        it "can add/remove inputs/results" do
          expect(response.status).to be(0)
          expect(parsed_response).to eq("bar" => "bar", "baz" => "defaultbaz")
        end
      end

      context "when using yaml sugar" do
        let(:command_class) do
          stub_class("SomeCommand", Foobara::Command) do
            inputs do
              foo :required do
                foo :string, :required
                bar :string, :required
              end
              bar :required do
                foo :string, :required
                bar :string, :required
              end
              baz :required do
                foo :string, :required
                bar :string, :required
              end
            end
            result :duck

            def execute
              inputs
            end
          end
        end

        let(:inputs_transformers) do
          { yaml: [:foo, :bar] }
        end

        let(:inputs) do
          {
            foo: "---\n:foo: foofoo\n:bar: foofoofoo\n",
            bar: "---\n:foo: barbar\n:bar: barbarbar\n",
            baz: { foo: "bazbaz", bar: "bazbazbaz" }
          }
        end

        it "sets the type to a string for the yaml inputs" do
          transformed_command = command_connector.transformed_command_from_name("SomeCommand")
          inputs_type = transformed_command.inputs_type

          expect(inputs_type.element_types[:foo].declaration_data).to eq(:string)
          expect(inputs_type.element_types[:bar].declaration_data).to eq(:string)
          expect(inputs_type.element_types[:baz].declaration_data[:type]).to eq(:attributes)

          expect(response.status).to be(0)
          expect(parsed_response).to eq(
            "foo" => { "foo" => "foofoo", "bar" => "foofoofoo" },
            "bar" => { "foo" => "barbar", "bar" => "barbarbar" },
            "baz" => { "foo" => "bazbaz", "bar" => "bazbazbaz" }
          )
        end
      end
    end
  end
end
