RSpec.describe Foobara::CommandConnector::Commands::Describe do
  let(:command_class) { described_class }
  let(:mock_manifestable) { Object.new }
  let(:mock_request) { Object.new }

  before do
    # Setup mock manifestable
    allow(mock_manifestable).to receive(:foobara_manifest).and_return({
                                                                        test: "manifest_data",
                                                                        version: "1.0.0"
                                                                      })
  end

  describe ".inputs_type_declaration" do
    let(:declaration) { command_class.inputs_type_declaration }

    it "uses attributes DSL format" do
      expect(declaration[:type]).to eq(:attributes)
      expect(declaration[:element_type_declarations]).to have_key(:manifestable)
      expect(declaration[:element_type_declarations]).to have_key(:request)
    end

    it "declares manifestable as required" do
      expect(declaration[:required]).to include(:manifestable)
    end

    it "declares request as optional" do
      expect(declaration[:required]).to_not include(:request)
    end
  end

  describe "#run" do
    context "with valid inputs" do
      let(:inputs) { { manifestable: mock_manifestable, request: mock_request } }

      it "executes successfully" do
        outcome = command_class.new(inputs).run
        expect(outcome).to be_success
        expect(outcome.result).to have_key(:test)
        expect(outcome.result).to have_key(:metadata)
      end

      it "includes metadata in the manifest" do
        outcome = command_class.new(inputs).run
        metadata = outcome.result[:metadata]
        expect(metadata).to have_key(:when)
        expect(metadata).to have_key(:foobara_version)
        expect(metadata[:foobara_version]).to eq(Foobara::Version::VERSION)
      end

      it "builds manifest from manifestable" do
        outcome = command_class.new(inputs).run
        expect(outcome.result[:test]).to eq("manifest_data")
        expect(outcome.result[:version]).to eq("1.0.0")
      end
    end

    context "when manifestable is missing" do
      let(:inputs) { { request: mock_request } }

      it "fails validation with errors" do
        command = command_class.new(inputs)
        outcome = command.run
        expect(outcome).to_not be_success
        expect(outcome.errors).to_not be_empty
      end
    end

    context "when request is missing" do
      let(:inputs) { { manifestable: mock_manifestable } }

      it "executes successfully since request is optional" do
        outcome = command_class.new(inputs).run
        expect(outcome).to be_success
        expect(outcome.result).to have_key(:test)
      end
    end

    context "with no inputs" do
      let(:inputs) { {} }

      it "fails validation due to missing required manifestable" do
        command = command_class.new(inputs)
        outcome = command.run
        expect(outcome).to_not be_success
        expect(outcome.errors).to_not be_empty
      end
    end
  end

  describe "input access" do
    let(:inputs) { { manifestable: mock_manifestable, request: mock_request } }
    let(:command) { command_class.new(inputs) }

    before do
      command.cast_and_validate_inputs
    end

    it "provides access to manifestable input" do
      expect(command.manifestable).to eq(mock_manifestable)
    end

    it "provides access to request input" do
      expect(command.request).to eq(mock_request)
    end
  end
end
