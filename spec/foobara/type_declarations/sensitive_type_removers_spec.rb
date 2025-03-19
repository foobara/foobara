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
            baz: { type: :string },
            bar: { type: :string },
            foo: { type: :string }
          },
          required: %i[bar foo],
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
              baz: { type: :string },
              foo: { type: :string },
              nested: {
                type: :attributes,
                element_type_declarations: {
                  baz: { type: :string },
                  foo: { type: :string }
                },
                required: [:foo],
                defaults: { foo: "foo" }
              },
              baz2: {
                type: :array,
                element_type_declaration: {
                  type: :attributes,
                  element_type_declarations: { foo: { type: :string } }
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
              baz: { type: :string },
              bar: { type: :string },
              foo: { type: :string }
            },
            required: %i[bar foo],
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
                foo: { type: :string }
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
                    required: %i[foo bar],
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
              required: %i[foo bar],
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
              foo: { type: :string },
              bar: { type: :string },
              baz: { type: :string },
              nested: {
                type: :attributes,
                element_type_declarations: {
                  foo: { type: :string },
                  bar: { type: :string },
                  baz: { type: :string }
                },
                required: %i[bar foo], defaults: { foo: "foo", bar: "bar" }
              },
              baz2: {
                type: :array,
                element_type_declaration: {
                  type: :attributes,
                  element_type_declarations: { foo: { type: :string } }
                }
              }
            },
            required: %i[bar foo],
            defaults: { foo: "foo", bar: "bar" }
          }
        )
      end
    end

    context "when model/entity/detatched entity" do
      let(:type) do
        stub_class "SomeModel", Foobara::Model do
          attributes do
            foo :string
            foo2 :string, :sensitive
          end
        end

        stub_class("InnerEntity", Foobara::Entity) do
          attributes do
            id :integer
            bar :string
            bar2 :string, :sensitive
          end
          primary_key :id
        end

        stub_class "InnerDetachedEntity", Foobara::DetachedEntity do
          attributes do
            id :integer
            baz :string
            baz2 :string, :sensitive
          end
          primary_key :id
        end

        stub_class "OuterEntity", Foobara::Entity do
          attributes do
            id :integer
            foo :string
            foo2 :string, :sensitive
            some_inner_entity InnerEntity
            some_detached_entity InnerDetachedEntity
            some_model SomeModel
          end
          primary_key :id
        end

        OuterEntity.entity_type
      end

      it "returns a declaration without sensitive attributes all the way down" do
        expect(
          type_declaration_without_sensitive_types[:attributes_declaration][:element_type_declarations]
        ).to eq(
          id: { type: :integer },
          foo: { type: :string },
          some_inner_entity: { type: :InnerEntity },
          some_detached_entity: { type: :InnerDetachedEntity },
          some_model: { type: :SomeModel }
        )
      end

      context "when subclass of an entity" do
        let(:type) do
          stub_class "SubEntity", super().target_class

          SubEntity.entity_type
        end

        it "returns a declaration without sensitive attributes all the way down" do
          expect(type.target_class).to eq(SubEntity)
          expect(SubEntity.superclass).to eq(OuterEntity)
          expect(
            type_declaration_without_sensitive_types[:attributes_declaration][:element_type_declarations]
          ).to eq(
            id: { type: :integer },
            foo: { type: :string },
            some_inner_entity: { type: :InnerEntity },
            some_detached_entity: { type: :InnerDetachedEntity },
            some_model: { type: :SomeModel }
          )
        end
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
