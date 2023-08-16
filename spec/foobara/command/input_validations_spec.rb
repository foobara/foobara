RSpec.describe Foobara::Command do
  context "with simple command" do
    let(:command_class) {
      Class.new(described_class) do
        input_schema(
          type: :attributes,
          element_type_declarations: {
            exponent: { type: :integer, max: 10, min: 1 },
            base: { type: :integer, required: true }
          },
          required: :exponent
        )

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

        class << self
          def name
            "CalculateExponential"
          end
        end
      end
    }

    let(:base) { 4 }
    let(:exponent) { 3 }
    let(:command) { command_class.new(base:, exponent:) }
    let(:state_machine) { command.state_machine }

    let(:outcome) { command.run }
    let(:result) { outcome.result }
    let(:errors) { outcome.errors }
    let(:error) { errors.first }

    describe ".run!" do
      context  "when input requirements met" do
        it "is success" do
          expect(outcome).to be_success
          expect(result).to eq(64)
        end
      end

      context "when input requirements not met" do
        context "when too high" do
          let(:exponent) { 13 }

          it "is not success" do
            expect(outcome).to_not be_success
            expect(errors.size).to eq(1)
            expect(error.context).to eq(max: 10, value: 13)
            expect(error.message).to be_a(String)
            expect(error.symbol).to eq(:max_exceeded)
            expect(error.path).to eq([:exponent])
            expect(error.attribute_name).to eq(:exponent)
          end
        end

        context "when too low" do
          let(:exponent) { -5 }

          it "is not success" do
            expect(outcome).to_not be_success
            expect(errors.size).to eq(1)
            expect(error.context).to eq(min: 1, value: -5)
            expect(error.message).to be_a(String)
            expect(error.symbol).to eq(:below_minimum)
            expect(error.path).to eq([:exponent])
            expect(error.attribute_name).to eq(:exponent)
          end
        end
      end

      context "when input validator data doesn't match expected data type" do
        let(:exponent) { "asdf" }

        it "is not success" do
          expect(outcome).to_not be_success
          expect(errors.size).to eq(1)
          expect(error.context).to eq(value: exponent, cast_to: :integer)
          expect(error.message).to be_a(String)
          expect(error.symbol).to eq(:cannot_cast)
          expect(error.path).to eq([:exponent])
          expect(error.attribute_name).to eq(:exponent)
        end
      end

      context "when unknown validator is applied" do
        let(:command_class2) {
          Class.new(command_class) do
            input_schema(
              type: :attributes,
              element_type_declarations: {
                exponent: { type: :integer, max: 10, not_valid: :whatever },
                base: { type: :integer, required: true }
              },
              required: :exponent
            )
          end
        }

        let(:command) { command_class2.new(base:, exponent:) }

        it "is raises" do
          expect {
            outcome
          }.to raise_error(Foobara::Model::Schema::InvalidSchemaError, /\bnot_valid\b/)
        end
      end
    end
  end
end
