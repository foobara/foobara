RSpec.describe Foobara::TypeDeclarations::TypeBuilder do
  after do
    Foobara.reset_alls
  end

  let(:type_builder) do
    Foobara::GlobalDomain.foobara_type_builder
  end

  describe "#type_for_declaration" do
    context "when declaring an array of attributes" do
      context "when via :array and a block" do
        it "builds the expected type" do
          type = type_builder.type_for_declaration(:array) do
            foo :string, :required
          end

          expect(type.declaration_data).to eq(
            type: :array,
            element_type_declaration: {
              type: :attributes,
              element_type_declarations: { foo: :string },
              required: [:foo]
            }
          )
        end
      end

      context "when via array literal with a lambda" do
        it "builds the expected type" do
          type = type_builder.type_for_declaration([-> {
            foo :string, :required
          }])

          expect(type.declaration_data).to eq(
            type: :array,
            element_type_declaration: {
              type: :attributes,
              element_type_declarations: { foo: :string },
              required: [:foo]
            }
          )
        end
      end
    end
  end
end
