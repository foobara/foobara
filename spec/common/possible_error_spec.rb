RSpec.describe Foobara::PossibleError do
  describe "#initialize" do
    context "with key and error_class" do
      let(:possible_error) { described_class.new(error_class, key:) }

      let(:key) { "data.foo.bar.baz" }
      let(:error_class) { Foobara::RuntimeError }

      it "creates an instance" do
        expect(possible_error.key.path).to eq([:foo, :bar])
        expect(possible_error.key.symbol).to eq(:baz)
        expect(possible_error.key.category).to eq(:data)
        expect(possible_error.error_class).to eq(Foobara::RuntimeError)
      end
    end
  end
end
