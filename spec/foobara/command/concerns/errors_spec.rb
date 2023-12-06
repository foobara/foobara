RSpec.describe Foobara::Command::Concerns::Errors do
  context "with simple command" do
    let(:command_base_class) {
      stub_class(:CalculateExponentBase, Foobara::Command) do
        inputs(
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
      end
    }

    let(:base) { 4 }
    let(:exponent) { 3 }
    let(:command) { command_class.new(base:, exponent:) }

    let(:outcome) { command.run }
    let(:result) { outcome.result }
    let(:errors) { outcome.errors }
    let(:error) { errors.first }

    context "with additional possible input error" do
      let(:command_class) do
        stub_class(:CalculateExponent, command_base_class) do
          possible_input_error(:exponent, :cannot_be_five, value: :integer, cannot_be: :integer)

          def validate
            super

            if exponent == 5
              add_input_error(
                input: :exponent,
                symbol: :cannot_be_five,
                message: "Cannot be five",
                context: { value: exponent, cannot_be: 5 }
              )
            end
          end
        end
      end

      context  "when input requirements met" do
        it "is success" do
          expect(outcome).to be_success
          expect(result).to eq(64)
        end
      end

      context "when input requirements not met" do
        let(:exponent) { 5 }

        it "is not success" do
          expect(outcome).to_not be_success
          expect(errors.size).to eq(1)
          expect(error).to be_a(Foobara::Value::DataError)
          expect(error.context).to eq(value: 5, cannot_be: 5)
          expect(error.message).to eq("Cannot be five")
          expect(error.symbol).to eq(:cannot_be_five)
          expect(error.path).to eq([:exponent])
          expect(error.attribute_name).to eq(:exponent)
        end
      end
    end

    context "with possible runtime error" do
      let(:command_class) do
        stub_class(:CalculateExponentCannotBeFive, command_base_class) do
          possible_error(:exponent_cannot_be_five, value: :integer, cannot_be: :integer)

          def execute
            if exponent == 5
              add_runtime_error(
                symbol: :exponent_cannot_be_five,
                message: "Exponent cannot be five",
                context: { value: exponent, cannot_be: 5 }
              )
            else
              super
            end
          end
        end
      end

      context  "when no error" do
        it "is success" do
          expect(outcome).to be_success
          expect(result).to eq(64)
        end
      end

      context "when error" do
        let(:exponent) { 5 }

        it "is not success" do
          expect(outcome).to_not be_success
          expect(errors.size).to eq(1)
          expect(error).to be_a(Foobara::RuntimeError)
          expect(error.context).to eq(value: 5, cannot_be: 5)
          expect(error.message).to eq("Exponent cannot be five")
          expect(error.symbol).to eq(:exponent_cannot_be_five)
        end
      end
    end
  end
end
