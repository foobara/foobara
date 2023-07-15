RSpec.describe Foobara::Command::Callbacks do
  context "with simple command" do
    let(:command_class) {
      Class.new(Foobara::Command) do
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

      context "when there are various instance callbacks" do
        before do
          @before_execute_called = false
          command.before_execute do |c|
            expect(c).to be(command)
            @before_execute_called = true
          end
        end

        context "when success" do
          before do
            expect(outcome).to be_success
          end

          it "runs callbacks" do
            expect(@before_execute_called).to be(true)
          end
        end
      end
    end
  end
end
