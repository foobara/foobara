RSpec.describe Foobara::TypeDeclarations::TypeDeclarationHandlerRegistry do
  describe "global.schema_for" do
    subject { schema }

    context "with nothing but a primitive type" do
      let(:type) { described_class::Registry.global.schema_for({ type: }) }

      context "with a valid type" do
        let(:type) { :integer }

        it { is_expected.to be_valid }

        it "has the correct type", :focus do
          expect(schema.type).to eq(type)
        end

        context "when using sugar syntax" do
          let(:schema) { described_class::Registry.global.schema_for(type) }

          it { is_expected.to be_valid }

          it "has the correct type" do
            expect(schema.type).to eq(type)
          end
        end

        describe "casting" do
          subject { type_instance.process!(object) }

          let(:type_instance) { schema.to_type }

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
      let(:schema) { described_class::Registry.global.schema_for({ type:, schemas: }) }

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
        let(:schema) { described_class::Registry.global.schema_for(schemas) }

        it { is_expected.to be_valid }

        it "has the correct type" do
          expect(schema.type).to eq(type)
        end
      end
    end
  end
end
