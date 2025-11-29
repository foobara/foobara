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

    let(:error_class) do
      Foobara::Error.subclass(symbol:, message:, context: { foo: :symbol }, is_fatal: true)
    end
    let(:error) { error_class.new(context:) }

    context "when adding error instance" do
      it "creates and adds an error" do
        expect(error_collection).to be_empty

        error_collection.add_error(error)

        expect(error_collection).to_not be_empty
        expect(error_collection.size).to eq(1)
        error = error_collection.first
        expect(error).to be_a(Foobara::Error)
        expect(error.is_fatal).to be(true)
        expect(error.symbol).to eq(symbol)
        expect(error.message).to eq(message)
        expect(error.context).to eq(context)
      end
    end

    # Do we really need to support this?
    context "when adding error by hash" do
      around do |example|
        Foobara::TypeDeclarations.with_validate_error_context_disabled do
          example.run
        end
      end

      let(:error_hash) do
        {
          symbol:,
          message:,
          context:
        }
      end

      it "creates and adds an error" do
        expect(error_collection).to be_empty

        error_collection.add_error(error_hash)

        expect(error_collection).to_not be_empty
        expect(error_collection.size).to eq(1)
        error = error_collection.first
        expect(error).to be_a(Foobara::Error)
        expect(error.symbol).to eq(symbol)
        expect(error.message).to eq(message)
        expect(error.context).to eq(context)
      end
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
