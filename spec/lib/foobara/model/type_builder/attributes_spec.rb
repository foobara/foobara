RSpec.describe Foobara::TypeDeclarations::TypeDeclarationHandler::Concerns::TypeBuilding do
  let(:type) {
    Foobara::TypeDeclarations::TypeDeclarationHandlerRegistry.global.process!(type_declaration)
  }

  describe "defaults" do
    context "when type_declaration has top-level defaults hash" do
      let(:type_declaration) do
        {
          type: :attributes,
          attribute_types: {
            a: :integer,
            b: :integer,
            c: :integer
          },
          defaults: {
            b: 1,
            c: "2"
          }
        }
      end

      it "applies defaults when expected and casts where expected" do
        attributes = type.process!(a: 100, b: 200, c: "300")
        expect(attributes).to eq(a: 100, b: 200, c: 300)

        attributes = type.process!(a: 100, c: "300")
        expect(attributes).to eq(a: 100, b: 1, c: 300)

        attributes = type.process!(a: 100)
        expect(attributes).to eq(a: 100, b: 1, c: 2)
      end
    end

    context "when type_declaration specifies defaults on a per-attribute level" do
      let(:type_declaration) do
        {
          type: :attributes,
          attribute_types: {
            a: { type: :integer  },
            b: { type: :integer, default: 1 },
            c: { type: :integer, default: "2" }
          }
        }
      end

      it "applies defaults when expected" do
        attributes = type.process!(a: 100, b: 200, c: "300")
        expect(attributes).to eq(a: 100, b: 200, c: 300)

        attributes = type.process!(a: 100, c: "300")
        expect(attributes).to eq(a: 100, b: 1, c: 300)

        attributes = type.process!(a: 100)
        expect(attributes).to eq(a: 100, b: 1, c: 2)
      end
    end
  end

  describe "required attributes" do
    context "when type_declaration has top-level required array" do
      let(:type_declaration) do
        {
          type: :attributes,
          attribute_types: {
            a: :integer,
            b: :integer,
            c: :integer
          },
          required: %i[a c]
        }
      end

      it "gives errors when required fields missing" do
        outcome = type.process(a: 100, b: 200, c: "300")
        expect(outcome).to be_success

        outcome = type.process(a: 100, c: "300")
        expect(outcome).to be_success

        outcome = type.process(b: 100, c: "300")
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                %i[
                                                                                  a missing_required_attribute
                                                                                ]
                                                                              ])

        outcome = type.process(b: 100)
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                %i[
                                                                                  a missing_required_attribute
                                                                                ],
                                                                                %i[c
                                                                                   missing_required_attribute]
                                                                              ])

        outcome = type.process({})
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                %i[
                                                                                  a missing_required_attribute
                                                                                ],
                                                                                %i[c
                                                                                   missing_required_attribute]
                                                                              ])
      end
    end

    context "when type_declaration has per-attribute required flag" do
      let(:type_declaration) do
        {
          type: :attributes,
          attribute_types: {
            a: { type: :integer, required: true },
            b: { type: :integer, required: false },
            c: { type: :integer, required: true }
          }
        }
      end

      it "gives errors when required fields missing" do
        outcome = type.process(a: 100, b: 200, c: "300")
        expect(outcome).to be_success

        outcome = type.process(a: 100, c: "300")
        expect(outcome).to be_success

        outcome = type.process(b: 100, c: "300")
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                %i[
                                                                                  a missing_required_attribute
                                                                                ]
                                                                              ])

        outcome = type.process(b: 100)
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                %i[
                                                                                  a missing_required_attribute
                                                                                ],
                                                                                %i[c
                                                                                   missing_required_attribute]
                                                                              ])

        outcome = type.process({})
        expect(outcome).to_not be_success
        expect(outcome.errors.map { |e| [e.attribute_name, e.symbol] }).to eq([
                                                                                %i[
                                                                                  a missing_required_attribute
                                                                                ],
                                                                                %i[c
                                                                                   missing_required_attribute]
                                                                              ])
      end
    end
  end
end
