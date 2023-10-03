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
    described_class.new
  end

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

  describe "#run_command" do
    before do
      command_connector.connect(command_class)
    end

    it "runs the command" do
      expect(outcome).to be_success
      expect(result).to be(8)

      expect(response.status).to be(200)
      expect(response.headers).to eq({})
      expect(response.body).to eq("8")
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

      let(:user_class) do
        stub_class = ->(klass) { stub_const(klass.name, klass) }

        Class.new(Foobara::Entity) do
          class << self
            def name
              "User"
            end
          end

          stub_class.call(self)

          attributes id: :integer
          primary_key :id
        end
      end

      context "when not found error" do
        let(:query_string) { "user=100" }
        let(:body) { "" }

        it "fails" do
          expect(outcome).to_not be_success

          expect(response.status).to be(404)
          expect(response.headers).to eq({})

          errors = JSON.parse(response.body)

          expect(errors.size).to eq(1)
          expect(errors.keys.first).to eq("runtime.user_not_found")
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
  end
end
