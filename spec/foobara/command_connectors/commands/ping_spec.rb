Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Commands::Ping do
  let(:command_connector) do
    Foobara::CommandConnectors::Http.new(authenticator:, default_serializers:)
  end

  let(:authenticator) { nil }
  let(:default_serializers) do
    [Foobara::CommandConnectors::ErrorsSerializer, Foobara::CommandConnectors::JsonSerializer]
  end

  let(:base) { 2 }
  let(:exponent) { 3 }

  let(:request) { command_connector.run(path:, method:, headers:, query_string:, body:) }
  let(:response) { request.response }
  let(:outcome) { request.outcome }
  let(:result) { request.result }

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

  describe "#run_command" do
    describe "with describe path" do
      let(:path) { "/ping" }

      it "describes the command" do
        expect(outcome).to be_success
        data = JSON.parse(response.body)
        expect(data["pong"]).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}$/)
      end
    end
  end
end
