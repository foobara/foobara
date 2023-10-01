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
    end
  end
end
