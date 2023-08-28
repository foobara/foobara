RSpec.describe Foobara::Value::Processor::Runner do
  let(:processor_class) {
    Class.new(Foobara::Value::Transformer) do
      self::Error = Class.new(Foobara::Value::AttributeError) do # rubocop:disable RSpec/LeakyConstantDeclaration
      end

      attr_accessor :calls

      def initialize(...)
        super
        self.calls = 0
      end

      def transform(value)
        self.calls += 1
        value * 2
      end
    end
  }

  let(:processor) { processor_class.new }

  let(:runner) { processor.runner(value) }
  let(:value) { 5 }

  describe "calling a runner method twice" do
    it "memoizes" do
      expect(processor.calls).to eq(0)
      expect(runner.transform).to eq(10)
      expect(processor.calls).to eq(1)
      expect(runner.transform).to eq(10)
      expect(processor.calls).to eq(1)
    end
  end
end
