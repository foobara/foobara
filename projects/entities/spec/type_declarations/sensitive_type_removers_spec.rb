RSpec.describe Foobara::TypeDeclarations do
  after { Foobara.reset_alls }

  describe ".remove_sensitive_types" do
    let(:strict_type_declaration) do
      type.declaration_data
    end

    let(:type_declaration_without_sensitive_types) do
      described_class.remove_sensitive_types(strict_type_declaration)
    end

    context "when model/entity/detached entity" do
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
          id: :integer,
          foo: :string,
          some_inner_entity: :InnerEntity,
          some_detached_entity: :InnerDetachedEntity,
          some_model: :SomeModel
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
            id: :integer,
            foo: :string,
            some_inner_entity: :InnerEntity,
            some_detached_entity: :InnerDetachedEntity,
            some_model: :SomeModel
          )
        end
      end
    end
  end
end
