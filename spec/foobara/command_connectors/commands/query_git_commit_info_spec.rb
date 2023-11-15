Foobara::Monorepo.project :command_connectors_http

RSpec.describe Foobara::CommandConnectors::Commands::Ping do
  let(:command_connector) do
    Foobara::CommandConnectors::Http.new(default_serializers:)
  end

  let(:default_serializers) do
    [Foobara::CommandConnectors::ErrorsSerializer, Foobara::CommandConnectors::JsonSerializer]
  end

  let(:response) { command_connector.run(path:) }

  describe "#run_command" do
    describe "with describe path" do
      let(:path) { "/query_git_commit_info" }
      let(:file_name) { "git_commit_info.json" }

      context "without git_commit_info.json file" do
        it "describes the command" do
          expect(response.status).to be(422)
          data = JSON.parse(response.body)
          error = data.first
          expect(error["key"]).to eq("runtime.git_commit_info_file_not_found")
          expect(error["message"]).to include(file_name)
        end
      end

      context "with git_commit_info.json file" do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(file_name).and_return(true)

          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read).with(file_name).and_return(file_contents)
        end

        let(:file_contents) do
          <<-HERE
            {
              "commit": "00089edf2e6416addf7bc2370d5974a7a7c3c9ab",
              "author": "Miles Georgi <azimux@gmail.com>",
              "date": "Wed Nov 15 03:21:12 2023 +0000",
              "message": "Add env vars for foobara http connector response headers"
            }
          HERE
        end

        it "contains the sha1" do
          expect(response.status).to be(200)
          data = JSON.parse(response.body)
          expect(data).to eq(
            "commit" => "00089edf2e6416addf7bc2370d5974a7a7c3c9ab",
            "author" => "Miles Georgi <azimux@gmail.com>",
            "date" => "Wed Nov 15 03:21:12 2023 +0000",
            "message" => "Add env vars for foobara http connector response headers"
          )
        end
      end
    end
  end
end
