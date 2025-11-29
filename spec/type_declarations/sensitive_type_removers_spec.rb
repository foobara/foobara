RSpec.describe Foobara::TypeDeclarations do
  after { Foobara.reset_alls }

  describe ".remove_sensitive_types" do
    let(:strict_type_declaration) do
      type.declaration_data
    end

    let(:type_declaration_without_sensitive_types) do
      described_class.remove_sensitive_types(strict_type_declaration)
    end

    context "when attributes" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration do
          foo :string, :required, default: "foo"
          bar :string, :required, default: "bar"
          bar2 :string, :sensitive, :required, default: "bar2"
          baz :string
        end
      end

      it "strips out the sensitive attributes" do
        expect(type_declaration_without_sensitive_types).to eq(
          type: :attributes,
          element_type_declarations: {
            baz: :string,
            bar: :string,
            foo: :string
          },
          required: [:bar, :foo],
          defaults: { foo: "foo", bar: "bar" }
        )
      end

      context "when nested sensitive stuff" do
        let(:type) do
          Foobara::Domain.current.foobara_type_from_declaration do
            foo :string, :required, default: "foo"
            bar :string, :sensitive, :required, default: "bar"
            baz :string
            nested do
              foo :string, :required, default: "foo"
              bar :string, :sensitive, :required, default: "bar"
              baz :string
            end
            baz2 :array do
              baz3 :string, :sensitive
              foo :string
            end
          end
        end

        it "strips out the sensitive attributes all the way down" do
          expect(type_declaration_without_sensitive_types).to eq(
            type: :attributes,
            element_type_declarations: {
              baz: :string,
              foo: :string,
              nested: {
                type: :attributes,
                element_type_declarations: {
                  baz: :string,
                  foo: :string
                },
                required: [:foo],
                defaults: { foo: "foo" }
              },
              baz2: {
                type: :array,
                element_type_declaration: {
                  type: :attributes,
                  element_type_declarations: { foo: :string }
                }
              }
            },
            required: [:foo],
            defaults: { foo: "foo" }
          )
        end
      end

      context "when no sensitive attributes" do
        let(:type) do
          Foobara::Domain.current.foobara_type_from_declaration do
            foo :string, :required, default: "foo"
            bar :string, :required, default: "bar"
            baz :string
          end
        end

        it "gives the type declaration unchanged" do
          expect(type_declaration_without_sensitive_types).to eq(
            type: :attributes,
            element_type_declarations: {
              baz: :string,
              bar: :string,
              foo: :string
            },
            required: [:bar, :foo],
            defaults: { foo: "foo", bar: "bar" }
          )
        end
      end

      context "when there's no direct sensitive attributes but an attribute contains a sensitive attribute" do
        let(:type) do
          Foobara::Domain.current.foobara_type_from_declaration do
            foo do
              foo :string
              baz :string, :sensitive
            end
          end
        end

        it "strips out the nested sensitive attribute" do
          expect(type_declaration_without_sensitive_types[:element_type_declarations]).to eq(
            foo: {
              type: :attributes,
              element_type_declarations: {
                foo: :string
              }
            }
          )
        end
      end
    end

    context "when array" do
      let(:type) do
        Foobara::Domain.current.foobara_type_from_declaration(
          [
            { type: :attributes,
              element_type_declarations:
               { foo: { type: :string },
                 bar: {  type: :string },
                 bar2: { sensitive: true, type: :string },
                 baz: { type: :string },
                 nested:
                  { type: :attributes,
                    element_type_declarations: {
                      foo: { type: :string },
                      bar: { type: :string },
                      bar2: {
                        sensitive: true, type: :string
                      }, baz: { type: :string }
                    },
                    required: [:foo, :bar],
                    defaults: { foo: "foo", bar: "bar" } },
                 baz2: {
                   type: :array,
                   element_type_declaration: {
                     type: :attributes,
                     element_type_declarations: {
                       baz3: { sensitive: true, type: :string },
                       foo: { type: :string }
                     }
                   }
                 } },
              required: [:foo, :bar],
              defaults: { foo: "foo", bar: "bar" } }

          ]
        )
      end

      it "strips out the sensitive attributes all the way down" do
        expect(type_declaration_without_sensitive_types).to eq(
          type: :array,
          element_type_declaration: {
            type: :attributes,
            element_type_declarations: {
              foo: :string,
              bar: :string,
              baz: :string,
              nested: {
                type: :attributes,
                element_type_declarations: {
                  foo: :string,
                  bar: :string,
                  baz: :string
                },
                required: [:bar, :foo], defaults: { foo: "foo", bar: "bar" }
              },
              baz2: {
                type: :array,
                element_type_declaration: {
                  type: :attributes,
                  element_type_declarations: { foo: :string }
                }
              }
            },
            required: [:bar, :foo],
            defaults: { foo: "foo", bar: "bar" }
          }
        )
      end
    end

    context "when non-sensitive built-in type" do
      let(:type) do
        Foobara::BuiltinTypes[:integer]
      end

      it "returns the declaration unmodified" do
        expect(type_declaration_without_sensitive_types).to eq(strict_type_declaration)
      end
    end
  end
end
