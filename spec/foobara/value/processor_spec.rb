RSpec.describe Foobara::Value::Processor do
  let(:processor_class) {
    Class.new(described_class) do
      self::Error = Class.new(Foobara::Value::AttributeError) do # rubocop:disable RSpec/LeakyConstantDeclaration
        class << self
          def context_schema
            {
              a: :integer,
              b: :symbol
            }
          end
        end
      end

      def process(_value)
        Foobara::Outcome.error(build_error(symbol: :foo, message: "some error", context: {}))
      end
    end
  }

  let(:processor) { processor_class.new }

  describe "processor_data_given?" do
    subject { processor.declaration_data_given? }

    context "when initialized without data" do
      it { is_expected.to be_falsey }
    end

    context "when initialized with data" do
      let(:processor) { processor_class.new(foo: :bar) }

      it { is_expected.to be_truthy }
    end
  end

  describe "error_context_type" do
    subject { processor.error_context_type }

    it { is_expected.to be_a(Foobara::Types::AtomType) }
  end

  describe "#process!" do
    context "when is an error" do
      it "raises" do
        expect {
          processor.process!(123)
        }.to raise_error(processor_class::Error)
      end
    end
  end
end
