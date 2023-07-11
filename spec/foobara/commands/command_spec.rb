
RSpec.describe Foobara::Command do
  context "with simple command" do
    let(:command_class) {
      Class.new(described_class) do
        class << self
          def name
            "CalculateExponential"
          end
        end

        input_schema(
          exponent: :integer,
          base: :integer
        )

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
    let(:exponential) { 3 }

    let(:command) { command_class.new(base:, exponential:) }

    describe ".run!" do
      let(:outcome) { command.run }
      let(:result) { outcome.result }

      it "is success", skip: "too lazy to code this up right now" do
        expect(outcome).to be_success
        expect(result).to eq(64)
      end
    end
  end
end
