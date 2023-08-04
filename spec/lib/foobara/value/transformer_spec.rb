module Foobara
  module Value
    RSpec.describe Transformer do
      let(:outcome) { transformer.call(value) }
      let(:result) { outcome.result }

      describe "#call" do
        context "when it is a transformer class that doubles" do
          let(:transformer_class) do
            Class.new(Transformer) do
              def transform(int)
                int + int
              end
            end
          end

          let(:value) { 3 }
          let(:transformer) { transformer_class.new }

          it "returns an outcome" do
            expect(transformer.transform(3)).to eq(6)
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

        let(:transformer_class) do
          described_class.class_from(metadata:) { |x| x + x }
        end

        let(:transformer) do
          described_class.from(data:, metadata:) { |x| x + x }
        end

        it "returns the expected outcome and sets expected data/metadata" do
          expect(transformer.transform(value)).to eq(90)
          expect(outcome).to be_a(Outcome)
          expect(outcome).to be_success
          expect(result).to eq(90)
          expect(transformer.data_given?).to be(true)
          expect(transformer.data).to eq(data)
          expect(transformer.class.metadata).to eq(metadata)
        end
      end
    end
  end
end
