module Foobara
  module Value
    RSpec.describe Validator do
      let(:outcome) { validator.call(value) }
      let(:result) { outcome.result }
      let(:errors) { outcome.errors }
      let(:error) {
        Error.new(
          symbol: :invalid,
          message: "something is invalid"
        )
      }

      describe "#call" do
        context "when it is a validator class that doubles" do
          let(:validator_class) do
            Class.new(Validator) do
              def validation_errors(_int)
                error_class.new(
                  symbol: :invalid,
                  message: "something is invalid"
                )
              end
            end
          end

          let(:value) { 3 }
          let(:validator) { validator_class.new }

          it "returns an outcome" do
            expect(validator_class.error_class).to eq(Error)
            expect(validator.validation_errors(value)).to be_a(Error)
            expect(outcome).to be_a(Outcome)
            expect(outcome).to_not be_success
            expect(outcome.errors.size).to be(1)
            expect(outcome.errors.first).to be_a(Error)
          end
        end
      end

      describe ".from" do
        let(:data) { { foo: :bar } }
        let(:metadata) { { bar: :baz } }
        let(:value) { 45 }

        let(:validator_class) do
          described_class.class_from(metadata:) { error }
        end

        let(:validator) do
          described_class.from(data:, metadata:) { error }
        end

        it "returns the expected outcome and sets expected data/metadata" do
          expect(validator_class.error_class).to eq(Error)
          expect(validator.validation_errors(value)).to eq(error)
          expect(outcome).to be_a(Outcome)
          expect(outcome).to_not be_success
          expect(outcome.errors).to eq([error])
          expect(validator.data_given?).to be(true)
          expect(validator.data).to eq(data)
          expect(validator.class.metadata).to eq(metadata)
        end
      end
    end
  end
end
