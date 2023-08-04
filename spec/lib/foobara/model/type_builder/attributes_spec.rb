RSpec.describe Foobara::Model::Schema::Concerns::TypeBuilding do
  let(:schema) { Foobara::Model::Schema::Registry.global.schema_for(schema_hash) }
  let(:type) { schema.to_type }

  describe "defaults" do
    context "when schema has top-level defaults hash" do
      let(:schema_hash) do
        {
          type: :attributes,
          schemas: {
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

    context "when schema has specifies defaults on a per-attribute level" do
      let(:schema_hash) do
        {
          type: :attributes,
          schemas: {
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
    context "when schema has top-level required array" do
      let(:schema_hash) do
        {
          type: :attributes,
          schemas: {
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

    context "when schema has per-attribute required flag" do
      let(:schema_hash) do
        {
          type: :attributes,
          schemas: {
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
