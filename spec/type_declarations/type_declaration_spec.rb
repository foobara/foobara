RSpec.describe Foobara::TypeDeclaration do
  let(:declaration_data) do
    {
      foo: :integer,
      bar: :integer
    }
  end

  let(:type_declaration) do
    described_class.new(declaration_data)
  end

  describe "#delete" do
    it "deletes the expected attribute and results in a duped declaration" do
      expect(type_declaration.key?(:foo)).to be true
      expect(type_declaration).to_not be_duped

      type_declaration.delete(:foo)

      expect(type_declaration.key?(:foo)).to be false
      expect(type_declaration).to be_duped
    end

    context "when strict" do
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
        described_class.new(declaration_data, true)
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

    context "when absolutified" do
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
        Foobara::TypeDeclarations.strict do
          super()
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
          # Hmmm rubocop complains about !! use... TODO: disable that?
        }.to change { declaration.strict? == true }.from(true).to(false)
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
        Foobara::TypeDeclarations.strict_stringified do
          super()
        end
      end

      it "removes the element" do
        declaration = type_declaration.except(:required)

        expect(declaration.declaration_data).to eq(
          type: :attributes,
          element_type_declarations: {
            "foo" => "integer",
            "bar" => "integer"
          }
        )
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

  describe "#initialize" do
    context "when a type symbol" do
      let(:declaration_data) { :integer }

      it "sets the type and various flags" do
        expect(type_declaration.type).to be(Foobara::BuiltinTypes[:integer])

        expect(type_declaration.declaration_data).to eq(type: :integer)

        expect(type_declaration).to be_strict
        expect(type_declaration).to be_absolutified
        expect(type_declaration).to be_duped
        expect(type_declaration).to be_deep_duped
      end

      context "when absolutified" do
        let(:type_declaration) do
          described_class.new(declaration_data, true)
        end

        it "sets the type and various flags" do
          expect(type_declaration.type).to be(Foobara::BuiltinTypes[:integer])

          expect(type_declaration.declaration_data).to eq(type: :integer)

          expect(type_declaration).to be_strict
          expect(type_declaration).to be_absolutified
          expect(type_declaration).to be_duped
          expect(type_declaration).to be_deep_duped
        end
      end
    end
  end
end
