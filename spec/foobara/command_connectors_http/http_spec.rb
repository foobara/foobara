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

    context "unknown error" do
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
