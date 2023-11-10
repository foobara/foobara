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

  describe "#run_command" do
    describe "with describe path" do
      let(:path) { "/ping" }

      it "describes the command" do
        expect(response.status).to be(200)
        data = JSON.parse(response.body)
        expect(data["pong"]).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} [+-]\d{4}$/)
      end

      context "with git_sha1 file" do
        before do
          allow(File).to receive(:exist?).with("git_sha1").and_return(true)
          allow(File).to receive(:read).with("git_sha1").and_return("abc123")
        end

        it "contains the sha1" do
          expect(response.status).to be(200)
          data = JSON.parse(response.body)
          expect(data["git_sha1"]).to eq("abc123")
        end
      end
    end
  end
end
