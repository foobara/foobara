RSpec.describe Foobara::Command do
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
    let(:state_machine) { command.state_machine }

    describe ".run!" do
      let(:outcome) { command.run }
      let(:result) { outcome.result }

      it "is success" do
        expect(outcome).to be_success
        expect(result).to eq(64)
        expect(state_machine).to be_currently_succeeded
        expect(state_machine).to be_ever_succeeded
        expect(state_machine).to be_ever_initialized
        non_happy_path_transitions = %i[error fail reset]
        happy_path_transitions = state_machine.transitions - non_happy_path_transitions
        expect(state_machine.log.map(&:transition)).to match_array(happy_path_transitions)
      end
    end

    context "input doesn't exist", skip: "todo"
  end
end
