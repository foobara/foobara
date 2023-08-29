RSpec.describe Foobara::ErrorCollection do
  let(:error_collection) { described_class.new }

  describe "#success?" do
    context "when no errors" do
      it { is_expected.to be_success }
    end
  end

  describe "#add_error" do
    let(:symbol) { :s }
    let(:message) { "m" }
    let(:context) { { foo: :bar } }

    let(:error_class) { Foobara::Error.subclass(symbol:, message:, context_type_declaration: { foo: :symbol }) }
    let(:error) { error_class.new(context:) }

    it "creates and adds an error" do
      expect(error_collection).to be_empty

      error_collection.add_error(error)

      expect(error_collection).to_not be_empty
      expect(error_collection.size).to eq(1)
      error = error_collection.errors.first
      expect(error).to be_a(Foobara::Error)
      expect(error.symbol).to eq(symbol)
      expect(error.message).to eq(message)
      expect(error.context).to eq(context)
    end

    context "when passing the same error twice" do
      it "explodes" do
        error_collection.add_error(error)
        expect {
          error_collection.add_error(error)
        }.to raise_error(described_class::ErrorAlreadySetError)
      end
    end
  end
end
