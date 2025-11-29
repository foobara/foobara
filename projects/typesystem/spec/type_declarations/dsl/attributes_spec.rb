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
        array_of_attributes :array do
          timestamp :datetime
        end
      end

      expect(declaration.declaration_data).to eq(
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
          },
          array_of_attributes: {
            type: :array,
            element_type_declaration: {
              type: :attributes,
              element_type_declarations: {
                timestamp: :datetime
              }
            }
          }
        },
        required: [:first_name]
      )

      type = Foobara::Domain.current.foobara_type_from_declaration(declaration)

      expect(type).to be_a(Foobara::Types::Type)

      value = type.process_value!(
        first_name: "John",
        age: "30",
        nested: { foo: [1, "2"] },
        array_of_attributes: [
          { timestamp: 1_707_520_958 },
          { timestamp: 1_707_520_959 }
        ]
      )

      expect(value).to eq(
        first_name: "John",
        age: 30,
        nested: { foo: [1, 2], bar: 1.0 },
        array_of_attributes: [
          { timestamp: Time.parse("2024-02-09 23:22:38 +0000") },
          { timestamp: Time.parse("2024-02-09 23:22:39 +0000") }
        ]
      )
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

    context "when declaring sub-attributes via hash" do
      it "assumes you are trying to create an attribute whose type is attributes" do
        declaration = described_class.to_declaration do
          foo bar: :string
        end

        expect(declaration.declaration_data).to eq(
          element_type_declarations: {
            foo: {
              element_type_declarations: { bar: :string },
              type: :attributes
            }
          },
          type: :attributes
        )
      end
    end
  end
end
