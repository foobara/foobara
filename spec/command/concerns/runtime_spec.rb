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

  describe ".define_command_named_function" do
    context "when on Object" do
      before do
        stub_class "SomeCommand", Foobara::Command do
          def execute
            100
          end
        end
      end

      it "defines the command named function" do
        expect(SomeCommand()).to eq(100)
        expect(Object.SomeCommand()).to eq(100)
      end
    end

    context "when on a Module" do
      before do
        stub_module "SomeModule"

        stub_class "SomeModule::SomeCommand", Foobara::Command do
          def execute
            100
          end
        end
      end

      it "defines the command named function" do
        expect(SomeCommand()).to eq(100)
        expect(SomeModule::SomeCommand()).to eq(100)
        result = SomeModule.class_eval do
          SomeCommand()
        end
        expect(result).to eq(100)
      end
    end
  end
end
