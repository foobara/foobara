require "foobara/models/schema"

RSpec.describe Foobara::Models::Schema do
  describe ".new" do
    context "with nothing but a primitive type" do
      subject { schema }

      let(:schema) { described_class.new(type:) }

      context "with a valid type" do
        let(:type) { :integer }

        it { is_expected.to be_valid }

        it "returns a schema matching that type" do
          expect(schema.type).to eq(type)
        end
      end

      context "with an invalid type" do
        let(:type) { :not_a_real_type }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
