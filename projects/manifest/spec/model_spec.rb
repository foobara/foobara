RSpec.describe Foobara::Manifest do
  after do
    Foobara.reset_alls
  end

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new

    user_entity
    some_model
  end

  let(:manifest) { Foobara::Manifest::RootManifest.new(raw_manifest) }
  let(:raw_manifest) { Foobara.manifest }
  let(:user_entity) do
    stub_class "User", Foobara::Entity do
      attributes do
        id :integer
        first_name :string, :allow_nil
      end
      primary_key :id
    end
  end
  let(:model) { manifest.model_by_name("SomeModel") }

  describe "#has_associations?" do
    subject { model.has_associations? }

    context "when one of its attributes is an entity" do
      let(:some_model) do
        stub_class "SomeModel", Foobara::Model do
          attributes do
            user User
          end
        end
      end

      it { is_expected.to be(true) }
    end

    context "when one of its attributes is an array of entities" do
      let(:some_model) do
        stub_class "SomeModel", Foobara::Model do
          attributes do
            users [User]
          end
        end
      end

      it { is_expected.to be(true) }
    end

    context "when one of its attributes is a model that has entities in it" do
      let(:some_other_model) do
        stub_class "SomeOtherModel", Foobara::Model do
          attributes do
            users [User]
          end
        end
      end
      let(:some_model) do
        other_model_class = some_other_model

        stub_class "SomeModel", Foobara::Model do
          attributes do
            other other_model_class
          end
        end
      end

      it { is_expected.to be(true) }
    end
  end

  describe "#guaranteed_to_exist?" do
    subject { model.guaranteed_to_exist?(attribute_name) }

    let(:attribute_name) { :name }

    context "when the model has no delegates" do
      let(:some_model) do
        stub_class "SomeModel", Foobara::Model do
          attributes do
            name :string
          end
        end
      end

      it { is_expected.to be(false) }
    end

    context "when it's nested attributes" do
      let(:some_model) do
        stub_class "SomeModel", Foobara::Model do
          attributes do
            name do
              first :string
              last :string
            end
          end

          delegate_attribute :first, :name
        end
      end

      it { is_expected.to be(false) }
    end

    context "when required all the way down" do
      let(:some_model) do
        stub_class "SomeModel", Foobara::Model do
          attributes do
            name_parts :required do
              name :string, :required
              surname :string
            end
          end

          delegate_attribute :name, :name_parts
        end
      end

      it { is_expected.to be(true) }
    end
  end
end
