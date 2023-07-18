RSpec.describe Foobara::Model::Schema do
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

        describe "#casting" do
          let(:can_cast) { schema.can_cast?(object) }
          let(:casted_value) { schema.cast_from(object) }

          context "when cast is not required" do
            let(:object) { 123 }

            specify {
              expect(can_cast).to be true
              expect(casted_value).to eq(123)
            }
          end

          context "when cast is required" do
            let(:object) { "123" }

            specify {
              expect(can_cast).to be true
              expect(casted_value).to eq(123)
            }
          end
        end
      end

      context "with an invalid type" do
        let(:type) { :not_a_real_type }

        it { is_expected.to_not be_valid }
      end
    end

    context "with attributes" do
      let(:schema) { described_class.new(type:, schemas:) }

      let(:type) { :attributes }
      let(:schemas) {
        {
          base: 2,
          exponent: 3
        }
      }

      it { is_expected.to be_valid }

      it "has the correct type" do
        expect(schema.type).to eq(type)
      end

      context "when using sugar syntax" do
        let(:schema) { described_class.new(schemas) }

        it { is_expected.to be_valid }

        it "has the correct type" do
          expect(schema.type).to eq(type)
        end
      end
    end
  end
end
