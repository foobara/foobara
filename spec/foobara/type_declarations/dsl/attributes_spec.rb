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
  end
end
