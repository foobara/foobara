RSpec.describe Foobara::Command::Concerns::Runtime do
  let(:command_class) {
    Class.new(Foobara::Command) do
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

      class << self
        def name
          "CalculateExponential"
        end
      end
    end
  }

  let(:command) { command_class.new(inputs) }
  let(:inputs) { { base: 4, exponent: 3 } }

  describe ".raw_inputs_type_declaration" do
    subject { command_class.raw_inputs_type_declaration }

    it { is_expected.to eq(base: :integer, exponent: :integer) }
  end

  describe ".inputs_type_declaration" do
    subject { command_class.inputs_type_declaration }

    it {
      is_expected.to eq(
        type: :attributes,
        # TODO: make this work without having to set this value on the type declaration
        allowed_attributes: %i[exponent base],
        element_type_declarations: { base: { type: :integer }, exponent: { type: :integer } }
      )
    }
  end

  describe "#method_missing" do
    it "gives convenient access to the inputs" do
      command.cast_and_validate_inputs
      expect(command.respond_to?(:exponent)).to be(true)
      expect(command.base).to eq(4)
      expect(command.exponent).to eq(3)
      expect(command.run!).to eq(4**3)
    end
  end
end
