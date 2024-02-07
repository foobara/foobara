RSpec.describe Foobara::TypeDeclarations::Dsl::Attributes do
  describe ".to_declaration" do
    it "creates the expected declaration" do
      declaration = described_class.to_declaration do
        first_name :string, :required
        age :integer, "User's age", min: 0
        nested do
          foo [:integer]
          bar :float, default: 1.0
        end
      end

      expect(declaration).to eq(
        type: :attributes,
        element_type_declarations: {
          first_name: :string,
          age: { type: :integer, min: 0, description: "User's age" },
          nested: {
            type: :attributes,
            element_type_declarations: {
              foo: [:integer],
              bar: :float
            },
            defaults: {
              bar: 1.0
            }
          }
        },
        required: [:first_name]
      )

      type = Foobara::Domain.current.foobara_type_from_declaration(declaration)

      expect(type).to be_a(Foobara::Types::Type)
    end

    context "when accidentally creating an attribute due to calling a method that doesn't exist" do
      it "raises an informative error" do
        expect {
          described_class.to_declaration do
            attribute not_an_attribute(:asdf).whatever, description: "should fail"
          end
        }.to raise_error(Foobara::TypeDeclarations::Dsl::BadAttributeError)
      end

      context "when attribute doesn't have a type" do
        it "raises an informative error" do
          expect {
            described_class.to_declaration do
              attribute not_an_attribute, description: "should fail"
            end
          }.to raise_error(Foobara::TypeDeclarations::Dsl::NoTypeGivenError)
        end
      end
    end
  end
end
