require "foobara/models/schema"

RSpec.describe Foobara::Models::Schema do
  describe ".new" do
    subject { schema }

    context "with nothing but a primitive type" do
      let(:schema) { described_class.new(type:) }

      context "with a valid type" do
        let(:type) { :integer }

        it { is_expected.to be_valid }

        it "has the correct type" do
          expect(schema.type).to eq(type)
        end

        context "when using sugar syntax" do
          let(:schema) { described_class.new(type) }

          it { is_expected.to be_valid }

          it "has the correct type" do
            expect(schema.type).to eq(type)
          end
        end

        describe "#apply" do
          subject { schema.apply(object) }

          context "when cast is not required" do
            let(:object) { 123 }

            it { is_expected.to eq(123) }
          end

          context "when cast is required" do
            let(:object) { "123" }

            it { is_expected.to eq(123) }
          end
        end
      end

      context "with an invalid type" do
        let(:type) { :not_a_real_type }

        it { is_expected.not_to be_valid }
      end
    end
  end
end
