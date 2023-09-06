RSpec.describe Foobara::Command::Concerns::ResultType do
  context "with simple command" do
    let(:command_class) {
      Class.new(Foobara::Command) do
        inputs to_be_result: :duck
        result :integer

        def execute
          to_be_result
        end
      end
    }

    let(:command) { command_class.new(to_be_result:) }

    describe ".raw_result_type_declaration" do
      subject { command_class.raw_result_type_declaration }

      it { is_expected.to be(:integer) }
    end

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
        let(:to_be_result) { "not an integer" }

        it "raises" do
          expect { command.run }.to raise_error(Foobara::Command::Concerns::Result::CouldNotProcessResult)
          expect(command.outcome).to be_nil
          expect(command).to_not be_success
        end
      end
    end
  end
end
