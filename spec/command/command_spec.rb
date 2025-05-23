RSpec.describe Foobara::Command do
  context "with simple command" do
    let(:command_class) {
      stub_class "CalculateExponent", described_class do
        inputs do
          exponent :integer, :required
          base :integer, :required
        end

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
    }

    let(:base) { 4 }
    let(:exponent) { 3 }
    let(:inputs) do
      { base:, exponent: }
    end
    let(:command) { command_class.new(inputs) }
    let(:state_machine) { command.state_machine }

    let(:outcome) { command.run }
    let(:result) { outcome.result }
    let(:errors) { outcome.errors }
    let(:error) { errors.first }
    let(:errors_hash) { outcome.errors_hash }

    describe ".run!" do
      it "is success" do
        expect(outcome).to be_success
        expect(result).to eq(64)
        expect(state_machine).to be_currently_succeeded
        expect(state_machine).to be_ever_succeeded
        expect(state_machine).to be_ever_initialized
        non_happy_path_transitions = [:error, :fail, :reset]
        happy_path_transitions = state_machine.class.transitions - non_happy_path_transitions
        expect(state_machine.log.map(&:transition)).to match_array(happy_path_transitions)
      end
    end

    context "when input is required but missing" do
      let(:command) { command_class.new }

      it "is gives relevant errors" do
        expect(outcome).to_not be_success
        # TODO: let's make this input instead of attribute_name somehow...
        expect(errors.map { |e| [e.attribute_name, e.symbol] }).to eq(
          [
            [:base, :missing_required_attribute],
            [:exponent, :missing_required_attribute]
          ]
        )
      end
    end

    context "when given an unexpected input" do
      let(:command) { command_class.new(base:, exponent:, extra_junk: 123) }

      it "gives relevant errors" do
        expect(outcome).to_not be_success
        expect(errors.size).to be(1)
        expect(error.symbol).to eq(:unexpected_attributes)
        expect(error.context).to eq(allowed_attributes: [:exponent, :base], unexpected_attributes: [:extra_junk])
      end
    end

    context "when sub-attribute is not valid" do
      let(:command_class2) do
        stub_class :SomeCommand2, command_class do
          inputs(
            type: :attributes,
            element_type_declarations: {
              exponent: :integer,
              base: { type: :integer, required: true },
              foo: {
                bar: { type: :integer, max: 10, required: true }
              }
            },
            required: :exponent
          )
        end
      end

      let(:command) { command_class2.new(base: 2, exponent: 3, foo: { bar: "asdf" }) }

      let(:outcome) { command.run }
      let(:errors) { outcome.errors }
      let(:error) { outcome.errors.first }

      it "is not success and has expected error" do
        expect(outcome).to_not be_success
        expect(errors.size).to be(1)
        expect(error.attribute_name).to eq(:bar)
        expect(error.path).to eq([:foo, :bar])
        expect(error.symbol).to eq(:cannot_cast)
      end
    end

    context "when it takes a tuple" do
      let(:command_class) do
        stub_class "CalculateExponent", described_class do
          inputs operands: [:integer, :integer]

          def execute
            operands.first ** operands.last
          end
        end
      end

      let(:operands) { [2, 3] }
      let(:inputs) do
        { operands: }
      end

      it "can handle tuple inputs" do
        expect(outcome).to be_success
      end

      context "when the tuple is bad" do
        let(:operands) { [2, "asdf"] }

        it "gives an expected error" do
          expect(outcome).to_not be_success
          expect(errors_hash.keys).to eq(["data.operands.1.cannot_cast"])
        end
      end
    end

    context "when it takes an array" do
      let(:command_class) do
        stub_class "CalculateExponent", described_class do
          inputs operands: [:integer]

          def execute
            operands.first ** operands.last
          end
        end
      end

      let(:operands) { [2, 3] }
      let(:inputs) do
        { operands: }
      end

      it "can handle array inputs" do
        expect(outcome).to be_success
      end

      context "when the array is bad" do
        let(:operands) { [2, "asdf"] }

        describe ".lookup_error_class" do
          it "gives the expected class" do
            expect(
              command_class.lookup_error_class("data.operands.1.cannot_cast")
            ).to eq(Foobara::Value::Processor::Casting::CannotCastError)
          end
        end

        it "gives an expected error" do
          expect(outcome).to_not be_success
          expect(errors_hash.keys).to eq(["data.operands.1.cannot_cast"])
        end
      end
    end
  end
end
