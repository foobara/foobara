RSpec.describe Foobara::Namespace do
  let(:namespace_name) { "SomeNamespace" }
  let(:namespace) { described_class.new(namespace_name, parent_namespace:) }
  let(:scoped_object) { Object.new }
  let(:scoped_name) { "scoped_name" }
  let(:parent_namespace) { nil }

  before do
    scoped_object.extend(Foobara::Scoped)
    scoped_object.scoped_name = scoped_name
  end

  describe "#register" do
    it "registers the object and it can be found again" do
      expect(scoped_object.scoped_short_path).to eq([scoped_name])
      expect(scoped_object.scoped_full_path).to eq([scoped_name])
      expect(scoped_object.scoped_full_name).to eq(scoped_name)

      namespace.register(scoped_object)

      expect(scoped_object.namespace).to be(namespace)

      keys = [
        "scoped_name",
        ["scoped_name"]
      ]

      keys.each do |key|
        expect(namespace.lookup(key)).to be(scoped_object)
        expect(namespace.lookup!(key)).to be(scoped_object)
      end
    end

    context "with prefixes" do
      let(:scoped_name) { "some::prefix::scoped_name" }

      it "registers the object and it can be found again" do
        namespace.register(scoped_object)

        keys = [
          "some::prefix::scoped_name",
          "scoped_name",
          %w[some prefix scoped_name],
          ["scoped_name"],
          "::some::prefix::scoped_name"
        ]

        keys.each do |key|
          expect(namespace.lookup!(key)).to be(scoped_object)
          expect(namespace.lookup(key)).to be(scoped_object)
        end
      end

      context "with ambiguous prefixes" do
        let(:scoped_name) { "some::prefix::scoped_name" }
        let(:scoped_name2) { "some::prefix2::scoped_name" }

        let(:scoped_object2) do
          Object.new.tap do |object|
            object.extend(Foobara::Scoped)
            object.scoped_name = scoped_name2
          end
        end

        it "registers the objects and they can be found again" do
          namespace.register(scoped_object)
          namespace.register(scoped_object2)

          keys = [
            "scoped_name",
            ["scoped_name"]
          ]

          keys.each do |key|
            expect {
              namespace.lookup!(key)
            }.to raise_error(Foobara::Namespace::AmbiguousRegistry::AmbiguousLookupError)
          end

          keys = [
            "some::prefix::scoped_name",
            %w[some prefix scoped_name],
            "::some::prefix::scoped_name"
          ]

          keys.each do |key|
            expect(namespace.lookup!(key)).to be(scoped_object)
            expect(namespace.lookup(key)).to be(scoped_object)
          end

          keys = [
            "some::prefix2::scoped_name",
            %w[some prefix2 scoped_name],
            "::some::prefix2::scoped_name"
          ]

          keys.each do |key|
            expect(namespace.lookup!(key)).to be(scoped_object2)
            expect(namespace.lookup(key)).to be(scoped_object2)
          end
        end
      end

      context "with parent namespaces" do
        let(:grandparent_namespace) do
          described_class.new(%w[GrandparentPrefix1 GrandParentPrefix2 GrandparentNamespace])
        end

        let(:parent_namespace) do
          described_class.new("ParentNamespace", parent_namespace: grandparent_namespace)
        end

        it "registers the object and it can be found again" do
          expect(namespace.root_namespace).to be(grandparent_namespace)

          namespace.register(scoped_object)

          keys = [
            "some::prefix::scoped_name",
            "scoped_name",
            "GrandparentPrefix1::GrandParentPrefix2::GrandparentNamespace::ParentNamespace::SomeNamespace::some::" \
            "prefix::scoped_name",
            %w[some prefix scoped_name],
            ["scoped_name"],
            %w[GrandparentPrefix1 GrandParentPrefix2 GrandparentNamespace ParentNamespace SomeNamespace
               some prefix scoped_name]
          ]

          keys.each do |key|
            expect(namespace.lookup!(key)).to be(scoped_object)
            expect(namespace.lookup(key)).to be(scoped_object)
          end
        end
      end
    end

    context "when one namespace accesses another" do
      let(:depends_on_namespace) do
        described_class.new("DependsOnNamespace", accesses: namespace)
      end

      let(:does_not_depend_on_namespace) do
        described_class.new("DoesNotDependOnNamespace")
      end

      before do
        namespace.register(scoped_object)
      end

      it "can lookup names in the other namespace" do
        expect {
          does_not_depend_on_namespace.lookup!(scoped_name)
        }.to raise_error(Foobara::Namespace::NotFoundError)

        expect(namespace.lookup!(scoped_name)).to be(scoped_object)
        expect(depends_on_namespace.lookup!(scoped_name)).to be(scoped_object)
      end
    end
  end
end
