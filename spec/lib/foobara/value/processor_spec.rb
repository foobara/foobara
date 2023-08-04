module Foobara
  module Value
    RSpec.describe Processor do
      # value -> value is transformer
      # value -> [errors] is validator
      # value -> outcome is processor
      # value -> processor is processor registry
      # value -> validator is validator registry
      # value -> transformer is transformer registry
      #
      # [transformer] -> transformer is ChainedValidator
      # [validator] -> validator is ChainedValidator
      # [processor] -> processor is ChainedProcessor
      #
      # These should all operate off of ".call"
      #
      # What about for exposing schema metadata?
      # How about just a .metadata method?
      #
      # Foobara::Value::
      #
      # Transformer
      # ChainedTransformer
      # TransformerRegistry
      # Validator
      # ChainedValidator
      # ValidatorRegistry
      # Processor
      # ChainedProcessor
      # ProcessorRegistry

      let(:outcome) { processor.call(value) }
      let(:result) { outcome.result }

      describe "#call" do
        context "when it is a processor class that doubles" do
          let(:processor_class) do
            Class.new(described_class) do
              def call(int)
                Outcome.success(int + int)
              end
            end
          end

          let(:value) { 3 }
          let(:processor) { processor_class.new }

          it "returns an outcome" do
            expect(processor_class.error_class).to eq(Error)
            expect(outcome).to be_a(Outcome)
            expect(outcome).to be_success
            expect(result).to eq(6)
          end
        end
      end

      describe ".from" do
        let(:data) { { foo: :bar } }
        let(:metadata) { { bar: :baz } }
        let(:value) { 45 }

        let(:processor_class) do
          described_class.class_from(metadata:) { |x| Outcome.success(x + x) }
        end

        let(:processor) do
          described_class.from(data:, metadata:) { |x| Outcome.success(x + x) }
        end

        it "returns the expected outcome and sets expected data/metadata" do
          expect(processor_class.error_class).to eq(Error)
          expect(outcome).to be_a(Outcome)
          expect(outcome).to be_success
          expect(result).to eq(90)
          expect(processor.data_given?).to be(true)
          expect(processor.data).to eq(data)
          expect(processor.class.metadata).to eq(metadata)
        end
      end
    end
  end
end
