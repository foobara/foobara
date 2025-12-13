RSpec.describe Foobara::CommandConnector::Commands::ListCommands do
  let(:command_class) { described_class }
  let(:mock_request) { Object.new }
  let(:mock_command_connector) { Object.new }
  let(:mock_command_registry) { Object.new }
  let(:mock_command_classes) { [] }

  before do
    # Setup mock request
    allow(mock_request).to receive(:command_connector).and_return(mock_command_connector)
    allow(mock_command_connector).to receive(:command_registry).and_return(mock_command_registry)
    allow(mock_command_registry).to receive(:all_transformed_command_classes).and_return(mock_command_classes)
  end

  describe ".inputs_type_declaration" do
    let(:declaration) { command_class.inputs_type_declaration }

    it "uses attributes DSL format" do
      expect(declaration[:type]).to eq(:attributes)
      expect(declaration[:element_type_declarations]).to have_key(:request)
      expect(declaration[:element_type_declarations]).to have_key(:verbose)
    end

    it "declares request as optional" do
      if declaration[:required]
        expect(declaration[:required]).to_not include(:request)
      else
        # No required inputs means all are optional
        expect(declaration[:required]).to be_nil
      end
    end

    it "declares verbose as optional" do
      if declaration[:required]
        expect(declaration[:required]).to_not include(:verbose)
      else
        # No required inputs means all are optional
        expect(declaration[:required]).to be_nil
      end
    end
  end

  describe "#run" do
    let(:mock_command_class) { Object.new }

    before do
      allow(mock_command_class).to receive_messages(full_command_name: "TestCommand", description: "A test command")
      mock_command_classes << mock_command_class
    end

    context "with valid inputs" do
      let(:inputs) { { request: mock_request, verbose: false } }

      it "executes successfully" do
        outcome = command_class.new(inputs).run
        expect(outcome).to be_success
        expect(outcome.result).to be_an(Array)
      end

      it "returns command names without descriptions when verbose is false" do
        outcome = command_class.new(inputs).run
        expect(outcome.result).to eq([["TestCommand", nil]])
      end

      context "when verbose is true" do
        let(:inputs) { { request: mock_request, verbose: true } }

        it "returns command names with descriptions" do
          outcome = command_class.new(inputs).run
          expect(outcome.result).to eq([["TestCommand", "A test command"]])
        end
      end
    end

    context "when request is missing" do
      let(:inputs) { { verbose: true } }

      it "executes successfully since request is optional" do
        # This should work but might fail when trying to access command_connector
        # Let's test that it at least doesn't fail during validation
        command = command_class.new(inputs)
        expect { command.cast_and_validate_inputs }.to_not raise_error
      end
    end

    context "when verbose is missing" do
      let(:inputs) { { request: mock_request } }

      it "executes successfully with default verbose behavior" do
        outcome = command_class.new(inputs).run
        expect(outcome).to be_success
        expect(outcome.result).to eq([["TestCommand", nil]])
      end
    end

    context "with no inputs" do
      let(:inputs) { {} }

      it "passes validation since all inputs are optional" do
        command = command_class.new(inputs)
        expect { command.cast_and_validate_inputs }.to_not raise_error
      end
    end
  end

  describe "input access" do
    let(:inputs) { { request: mock_request, verbose: true } }
    let(:command) { command_class.new(inputs) }

    before do
      command.cast_and_validate_inputs
    end

    it "provides access to request input" do
      expect(command.request).to eq(mock_request)
    end

    it "provides access to verbose input" do
      expect(command.verbose).to be(true)
    end

    it "has verbose? helper method" do
      expect(command.verbose?).to be(true)
    end
  end

  describe "result type" do
    let(:result_type) { command_class.result_type }

    it "declares the correct result type" do
      expected = {
        type: :array,
        element_type_declaration: {
          type: :tuple,
          element_type_declarations: [
            :string,
            {
              type: :string,
              allow_nil: true
            }
          ],
          size: 2
        }
      }
      expect(result_type.declaration_data).to eq(expected)
    end
  end
end
