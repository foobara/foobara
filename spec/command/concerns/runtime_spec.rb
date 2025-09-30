RSpec.describe Foobara::CommandPatternImplementation::Concerns::Runtime do
  let(:command_class) {
    stub_class(:CalculateExponent, Foobara::Command) do
      inputs exponent: :integer,
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
    end
  }

  describe ".run!" do
    it "creates and runs the command and returns the result" do
      expect(command_class.run!(base: 4, exponent: 3)).to eq(4 ** 3)
    end
  end

  describe ".run" do
    it "creates and runs the command" do
      outcome = command_class.run(base: 4, exponent: 3)
      expect(outcome).to be_success
      expect(outcome.result).to eq(4 ** 3)
    end
  end
end
