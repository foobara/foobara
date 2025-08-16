# TODO: move this spec to the right project
RSpec.describe Foobara::ModelAttributeHelpers::Concerns::AttributeHelpers do
  after do
    Foobara.reset_alls
  end

  before do
    stub_class("SomeEntity", Foobara::Entity) do
      attributes do
        id :integer, :required, default: 10
        name :string, :required
        reviews [:integer], default: []
      end
      primary_key :id
    end
  end

  describe ".attributes_for_update" do
    it "calls attributes_for_aggregate_update" do
      expect(SomeEntity.foobara_attributes_for_update(require_primary_key: false)).to be_a(Hash)
    end
  end

  describe ".attributes_for_atom_update" do
    before do
      stub_class("SomeOtherEntity", Foobara::Entity) do
        attributes do
          id :integer
          reviews :array do
            stuff [SomeEntity], default: []
          end
        end
        primary_key :id
      end
    end

    it "returns a hash" do
      expect(SomeOtherEntity.foobara_attributes_for_atom_update(require_primary_key: false)).to be_a(Hash)
    end
  end

  describe ".attributes_for_create" do
    before do
      Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
    end

    let(:auth_user_class) do
      stub_class("AuthUser", Foobara::Entity) do
        attributes do
          id :integer
          username :string, :required
        end

        primary_key :id
      end
    end

    let(:user_class) do
      auth_user_class
      w = writer
      stub_class("User", Foobara::Entity) do
        attributes do
          id :integer
          stuff do
            things [:integer, AuthUser]
          end
          name :string, :required
          ssn :string, :private
        end
        primary_key :id
        delegate_attribute :username, [:stuff, :things, :"1", :username], writer: w
      end
    end
    let(:writer) { true }

    let(:for_create_declaration) do
      for_create_type.declaration_data
    end
    let(:for_create_type) do
      user_class.foobara_attributes_for_create(includes_primary_key:, include_private:, include_delegates:)
    end

    let(:includes_primary_key) { false }
    let(:include_private) { true }
    let(:include_delegates) { false }

    it "removes the primary key" do
      expect(for_create_declaration).to eq(
        type: :attributes,
        element_type_declarations: {
          name: :string,
          ssn: :string,
          stuff: {
            type: :attributes,
            element_type_declarations: {
              things: {
                type: :tuple,
                size: 2,
                element_type_declarations: [
                  :integer,
                  :AuthUser
                ]
              }
            }
          }
        },
        required: [:name]
      )
    end

    context "when there are delegated attributes and we set include_delegates" do
      let(:include_delegates) { true }

      it "includes the delegated attributes" do
        expect(for_create_declaration).to eq(
          type: :attributes,
          element_type_declarations: {
            name: :string,
            ssn: :string,
            username: :string,
            stuff: {
              type: :attributes,
              element_type_declarations: {
                things: {
                  type: :tuple,
                  size: 2,
                  element_type_declarations: [
                    :integer,
                    :AuthUser
                  ]
                }
              }
            }
          },
          required: [:name]
        )

        AuthUser.transaction do
          basil = AuthUser.create(username: "Basil")
          barbara = User.create(name: "Barbara", stuff: { things: [100, basil] })

          expect(barbara.username).to eq("Basil")
          barbara.username = "NewName"
          expect(basil.username).to eq("NewName")
        end
      end

      context "when private attributes are excluded" do
        let(:include_private) { false  }

        it "does not include private attributes" do
          expect(for_create_declaration).to eq(
            type: :attributes,
            element_type_declarations: {
              name: :string,
              username: :string,
              stuff: {
                type: :attributes,
                element_type_declarations: {
                  things: {
                    type: :tuple,
                    size: 2,
                    element_type_declarations: [
                      :integer,
                      :AuthUser
                    ]
                  }
                }
              }
            },
            required: [:name]
          )
        end
      end

      context "when the primary key is included" do
        let(:includes_primary_key) { true }

        it "includes the primary key" do
          expect(for_create_declaration).to eq(
            type: :attributes,
            element_type_declarations: {
              id: :integer,
              name: :string,
              ssn: :string,
              username: :string,
              stuff: {
                type: :attributes,
                element_type_declarations: {
                  things: {
                    type: :tuple,
                    size: 2,
                    element_type_declarations: [
                      :integer,
                      :AuthUser
                    ]
                  }
                }
              }
            },
            required: [:name]
          )
        end
      end
    end
  end

  describe ".attributes_for_find_by" do
    it "excludes required and defaults information" do
      expect(SomeEntity.foobara_attributes_for_find_by).to eq(
        type: :attributes,
        element_type_declarations: {
          id: :integer,
          name: :string,
          reviews: { type: :array, element_type_declaration: :integer }
        }
      )
    end
  end
end
