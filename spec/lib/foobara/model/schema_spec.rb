RSpec.describe Foobara::Model::Schema do
  describe ".for" do
    subject { schema }

    context "with nothing but a primitive type" do
      let(:schema) { described_class.for({ type: }) }

      context "with a valid type" do
        let(:type) { :integer }

        it { is_expected.to be_valid }

        it "has the correct type" do
          expect(schema.type).to eq(type)
        end

        context "when using sugar syntax" do
          let(:schema) { described_class.for(type) }

          it { is_expected.to be_valid }

          it "has the correct type" do
            expect(schema.type).to eq(type)
          end
        end

        describe "casting" do
          subject { type_instance.process!(object) }

          let(:type_instance) { Foobara::Model::TypeBuilder.type_for(schema) }

          context "when cast is not required" do
            let(:object) { 123 }

            it { is_expected.to be(object) }
          end

          context "when cast is required" do
            let(:object) { "123" }

            it { is_expected.to eq(123) }
          end
        end
      end

      context "with an invalid type" do
        let(:type) { :not_a_real_type }

        it { is_expected_to_raise(described_class::InvalidSchema) }
      end
    end

    context "with attributes" do
      # TODO: goofy that we have to wrap this in brackets
      let(:schema) { described_class.for({ type:, schemas: }) }

      let(:type) { :attributes }
      let(:schemas) {
        {
          base: :integer,
          exponent: :integer
        }
      }

      it { is_expected.to be_valid }

      it "has the correct type" do
        expect(schema.type).to eq(type)
      end

      context "when using sugar syntax" do
        let(:schema) { described_class.for(schemas) }

        it { is_expected.to be_valid }

        it "has the correct type" do
          expect(schema.type).to eq(type)
        end
      end
    end
  end
end
