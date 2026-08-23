# TODO: Get this out of here and into model project
RSpec.describe Foobara::Manifest::Model do
  after { Foobara.reset_alls }

  describe ".associations" do
    context "when the type has associations" do
      before do
        stub_class "SomeInnerInnerEntity", Foobara::Entity do
          attributes do
            id :integer
            bar :string, :required
          end
          primary_key :id
        end

        stub_class "SomeOuterModel", Foobara::Model do
          attributes do
            some_inner_inner_entities [:SomeInnerInnerEntity, :SomeInnerInnerEntity]
          end
        end

        stub_class("SomeInnerEntity", Foobara::Entity) do
          attributes do
            id :integer
            foo :string, :required
          end

          primary_key :id
        end

        stub_class("SomeOuterEntity", Foobara::Entity) do
          attributes do
            id :integer
            some_inner_entity :SomeInnerEntity
          end

          primary_key :id
        end

        Foobara::GlobalDomain.foobara_register_type(:some_type) do
          some_array [SomeOuterEntity]
          some_inner_model :SomeOuterModel
        end
      end

      context "when present in a manifest" do
        let(:command_class) do
          stub_class("SomeCommand", Foobara::Command) do
            inputs { some_object :some_type }
            result :some_type

            def execute = some_object
          end
        end

        let(:connector) do
          command_class
          Foobara::CommandConnector.new.tap do |connector|
            connector.connect(SomeCommand)
          end
        end
        let(:raw_manifest) { connector.foobara_manifest }

        it "can reproduce association info from the underlying associations in the types" do
          root_manifest = Foobara::Manifest::RootManifest.new(raw_manifest)

          manifest_type = root_manifest.type_by_name(:some_type)

          expect(manifest_type).to be_a(Foobara::Manifest::Type)

          associations = described_class.associations(manifest_type)

          expect(associations.keys).to contain_exactly(
            "some_array.#",
            "some_inner_model.some_inner_inner_entities.0",
            "some_inner_model.some_inner_inner_entities.1"
          )

          expect(associations.values).to all be_a(Foobara::Manifest::Entity)
        end
      end
    end
  end
end
