RSpec.describe Foobara::Commands::Command do
  context "with simple command" do
    let(:command_class) {
      Class.new(described_class) do
        input_schema exponent: :integer,
                     base: :integer

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

    describe ".run!" do
      let(:outcome) { command.run }
      let(:result) { outcome.result }

      it "is success" do
        expect(outcome).to be_success
        expect(result).to eq(64)
      end
    end

    context "input doesn't exist", skip: "todo"
  end
end
