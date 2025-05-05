RSpec.describe Foobara::Value::Processor do
  let(:processor_class) {
    stub_class "SomeProcessor", described_class do
      def process_value(value)
        if value == 123
          Foobara::Outcome.error(build_error(symbol: :foo, message: "some error", context: {}))
        else
          Foobara::Outcome.success(value)
        end
      end
    end.tap do
      stub_class "SomeProcessor::Error", Foobara::Value::DataError
    end
  }

  let(:processor) { processor_class.new(foo: :bar) }

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

  describe "#dup_processor" do
    context "when overriding declaration data" do
      it "dups the processor" do
        duped_processor = processor.dup_processor(declaration_data: { bar: "baz" })

        expect(processor.declaration_data).to eq(foo: :bar)
        expect(duped_processor.declaration_data).to eq(bar: "baz")
      end
    end
  end

  describe ".new_with_agnostic_args" do
    context "when requires declaration data" do
      let(:processor_class) do
        stub_class "SomeProcessor", described_class do
          class << self
            def requires_declaration_data?
              true
            end
          end
        end
      end

      context "when no declaration data provided" do
        let(:processor) { processor_class.new_with_agnostic_args }

        it "has true as its declaration data" do
          expect(processor.declaration_data).to be true
        end
      end
    end
  end
end
