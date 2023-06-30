require "foobara/models/schema"

RSpec.describe Foobara::Models::Schema do
  describe ".new" do
    context "with nothing but a primitive type" do
      let(:schema) { described_class.new(type:) }
      let(:type) { :integer }

      it "returns a schema matching that type" do
        expect(schema.type).to eq(type)
      end
    end
  end
end
