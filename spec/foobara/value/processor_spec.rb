RSpec.describe Foobara::Value::Processor do
  let(:processor_class) {
    Class.new(described_class) do
      self::Error = Class.new(Foobara::Value::DataError) do # rubocop:disable RSpec/LeakyConstantDeclaration
      end

      def process_value(value)
        if value == 123
          Foobara::Outcome.error(build_error(symbol: :foo, message: "some error", context: {}))
        else
          Foobara::Outcome.success(value)
        end
      end
    end
  }

  let(:processor) { processor_class.new(foo: :bar) }

  describe "processor_data_given?" do
    subject { processor.declaration_data_given? }

    context "when initialized without data" do
      let(:processor) { processor_class.new }

      it { is_expected.to be_falsey }
    end

    context "when initialized with data even if that data is falsey" do
      let(:processor) { processor_class.new(false) }

      it { is_expected.to be_truthy }
    end
  end

  describe "#process!" do
    context "when is an error" do
      it "raises" do
        expect {
          processor.process_value!(123)
        }.to raise_error(processor_class::Error)
      end
    end
  end

  describe "#process_outcome!" do
    context "when is an error" do
      it "raises" do
        expect {
          processor.process_outcome!(Foobara::Outcome.success(123))
        }.to raise_error(processor_class::Error)
      end
    end

    context "when is not an error" do
      it "gives the result" do
        expect(processor.process_outcome!(Foobara::Outcome.success(10))).to eq(10)
      end
    end
  end
end
