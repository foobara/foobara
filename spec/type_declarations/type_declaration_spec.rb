RSpec.describe Foobara::TypeDeclaration do
  let(:declaration_data) do
    {
      type: :attributes,
      element_type_declarations: {
        foo: :integer,
        bar: :integer
      },
      required: [:foo, :bar]
    }
  end

  let(:type_declaration) do
    described_class.new(declaration_data)
  end

  describe "#delete" do
    it "deletes the expected attribute and results in a duped declaration" do
      expect(type_declaration.key?(:required)).to be true
      expect(type_declaration).to_not be_duped

      type_declaration.delete(:required)

      expect(type_declaration.key?(:required)).to be false
      expect(type_declaration).to be_duped
    end

    context "when strict" do
      let(:type_declaration) do
        super().tap do |declaration|
          declaration.is_strict = true
        end
      end

      it "removes the strict flag" do
        expect {
          type_declaration.delete(:required)
        }.to change(type_declaration, :strict?).from(true).to(false)
      end

      context "when removing :type key" do
        it "clears the absolutified flag" do
          expect {
            type_declaration.delete(:type)

            expect(type_declaration.declaration_data).to eq(
              element_type_declarations: {
                foo: :integer,
                bar: :integer
              },
              required: [:foo, :bar]
            )
          }.to change(type_declaration, :absolutified?).from(true).to(false)
        end
      end
    end
  end

  describe "#except" do
    context "when strict" do
      let(:type_declaration) do
        super().tap do |declaration|
          declaration.is_strict = true
        end
      end

      it "removes the strict flag" do
        declaration = type_declaration

        expect {
          declaration = declaration.except(:required)

          expect(declaration.declaration_data).to eq(
            type: :attributes,
            element_type_declarations: {
              foo: :integer,
              bar: :integer
            }
          )
        }.to change { declaration.strict? }.from(true).to(false)
      end
    end

    context "when strict_stringified" do
      let(:declaration_data) do
        {
          "type" => "attributes",
          "element_type_declarations" => {
            "foo" => "integer",
            "bar" => "integer"
          },
          "required" => ["foo", "bar"]
        }
      end

      let(:type_declaration) do
        super().tap do |declaration|
          declaration.is_strict_stringified = true
        end
      end

      it "removes the strict flag" do
        declaration = type_declaration

        expect {
          declaration = declaration.except("required")

          expect(declaration.declaration_data).to eq(
            "type" => "attributes",
            "element_type_declarations" => {
              "foo" => "integer",
              "bar" => "integer"
            }
          )
        }.to change { declaration.strict_stringified? }.from(true).to(false)
      end
    end
  end

  describe "#clone" do
    context "when strict with a type" do
      let(:type_declaration) do
        super().tap do |declaration|
          declaration.is_strict = true
          declaration.type = Foobara::Domain.current.foobara_type_from_declaration(declaration_data)
        end
      end

      it "preserves the strict flag and type" do
        clone = type_declaration.clone

        expect(clone.type).to be_a(Foobara::Type)
        expect(clone).to be_strict
      end
    end
  end

  describe "#assign" do
    context "when strict" do
      let(:type_declaration) do
        super().tap do |declaration|
          declaration.is_strict = true
        end
      end

      it "copies everything over" do
        clone = described_class.new(foo: :bar)

        clone.assign(type_declaration)

        expect(clone.declaration_data).to eq(
          type: :attributes,
          element_type_declarations: {
            foo: :integer,
            bar: :integer
          },
          required: [:foo, :bar]
        )
        expect(clone).to be_absolutified
      end
    end
  end
end
