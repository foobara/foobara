RSpec.describe Foobara::TypeDeclarations::TypedTransformer do
  describe ".to/.to_type .from/.from_type" do
    context "when .type_declaration is a type" do
      let(:transformer_class) do
        stub_class :SomeTransformer, described_class do
          from :integer
          to :string

          def transform(int)
            int.to_s
          end
        end
      end

      it "results in typed transformer instances with those types" do
        transformer = transformer_class.instance

        expect(transformer_class.from_type).to eq(Foobara::BuiltinTypes[:integer])
        expect(transformer_class.to_type).to eq(Foobara::BuiltinTypes[:string])

        expect(transformer.from_type).to eq(Foobara::BuiltinTypes[:integer])
        expect(transformer.to_type).to eq(Foobara::BuiltinTypes[:string])

        expect(transformer.process_value!(5)).to eq("5")
      end
    end
  end

  describe "#from_type_declaration" do
    let(:transformer_class) do
      stub_class "Dearrayify", described_class do
        def from_type_declaration
          [to_type.declaration_data]
        end
      end
    end

    it "gives a way to define the define the from type in terms of the to type" do
      transformer = transformer_class.new(to: :integer)

      expect(transformer.from_type.declaration_data).to eq(
        Foobara::Domain.current.foobara_type_from_declaration([:integer]).declaration_data
      )
    end

    context "with no types" do
      let(:transformer_class) do
        stub_class :SomeTransformer, described_class do
          def transform(int)
            int.to_s
          end
        end
      end

      it "pointless, but it can still translate" do
        expect(transformer_class.from_type).to be_nil
        expect(transformer_class.to_type).to be_nil

        expect(transformer_class.instance.process_value!(5)).to eq("5")
      end
    end
  end
end
