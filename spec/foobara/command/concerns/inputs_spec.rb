RSpec.describe Foobara::Command::Concerns::Runtime do
  after do
    Foobara.reset_alls
  end

  let(:command_class) {
    stub_class(:CalculateExponent, Foobara::Command) do
      inputs exponent: :integer
      add_inputs base: :integer

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

  let(:command) { command_class.new(inputs) }
  let(:inputs) { { base: 4, exponent: 3 } }

  describe ".raw_inputs_type_declaration" do
    subject { command_class.raw_inputs_type_declaration }

    it { is_expected.to be_a(Hash) }
  end

  describe ".inputs_type_declaration" do
    subject { command_class.inputs_type_declaration }

    it {
      is_expected.to eq(
        type: :attributes,
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

  context "with a model as inputs" do
    let(:command_class) do
      stub_class(:CalculateInputs, Foobara::Model) do
        attributes do
          base :integer
          exponent :integer
        end
      end
      stub_class(:CalculateExponent, Foobara::Command) do
        inputs CalculateInputs

        def execute
          base**exponent
        end
      end
    end

    let(:command) { command_class.new(inputs) }
    let(:inputs) { { base: 4, exponent: 3 } }

    it "gives convenient access to the inputs" do
      expect(command.run!).to eq(4**3)
    end
  end
end
