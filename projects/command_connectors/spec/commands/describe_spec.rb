RSpec.describe Foobara::CommandConnector::Commands::Describe do
  let(:command_class) { described_class }
  let(:command) { command_class.new(inputs) }
  let(:outcome) { command.run }
  let(:result) { outcome.result }
  let(:manifestable) { Foobara::BuiltinTypes[:integer] }
  let(:request) { Foobara::CommandConnector::Request.new }

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
      let(:inputs) do
        { manifestable:, request: }
      end

      it "executes successfully" do
        expect(outcome).to be_success
        expect(outcome.result).to have_key(:metadata)
        metadata = outcome.result[:metadata]
        expect(metadata).to have_key(:when)
        expect(metadata).to have_key(:foobara_version)
        expect(metadata[:foobara_version]).to eq(Foobara::Version::VERSION)
      end
    end

    context "when manifestable is missing" do
      let(:inputs) { { request: } }

      it "fails validation with errors" do
        expect(outcome).to_not be_success
        expect(outcome.errors).to_not be_empty
      end
    end

    context "when request is missing" do
      let(:inputs) { { manifestable:  } }

      it "executes successfully since request is optional" do
        expect(outcome).to be_success
        expect(outcome.result[:declaration_data]).to be(:integer)
      end
    end

    context "with no inputs" do
      let(:inputs) { {} }

      it "fails validation due to missing required manifestable" do
        expect(outcome).to_not be_success
        expect(outcome.errors).to_not be_empty
      end
    end
  end

  describe "input access" do
    let(:inputs) { { manifestable:, request: } }

    before do
      command.cast_and_validate_inputs
    end

    it "provides access to inputs" do
      expect(command.manifestable).to be(manifestable)
      expect(command.request).to eq(request)
    end
  end
end
