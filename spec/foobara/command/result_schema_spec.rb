RSpec.describe Foobara::Command do
  context "with simple command" do
    let(:command_class) {
      Class.new(described_class) do
        input_schema to_be_result: :duck
        result_schema :integer

        def execute
          to_be_result
        end

        class << self
          def name
            "PassThrough"
          end
        end
      end
    }

    let(:command) { command_class.new(to_be_result:) }

    describe ".run!" do
      let(:outcome) { command.run }
      let(:result) { outcome.result }
      let(:errors) { outcome.errors }
      let(:error) { errors.first }

      context "when valid result that doesn't need casting" do
        let(:to_be_result) { 5 }

        it "is success" do
          expect(outcome).to be_success
          expect(result).to be(to_be_result)
        end
      end

      context "when valid result that does need casting" do
        let(:to_be_result) { "5" }

        it "is success" do
          expect(outcome).to be_success
          expect(result).to be_an(Integer)
          expect(result).to eq(5)
        end
      end

      context "when invalid result" do
        let(:to_be_result) { "asdf" }

        it "is not success" do
          expect(outcome).not_to be_success
          expect(error.symbol).to eq(:cannot_cast_to_integer)
          expect(error.message).to be_a(String)
          expect(error.context).to eq(
            cast_to: :integer,
            value: to_be_result
          )
        end
      end
    end
  end
end
