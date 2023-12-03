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
      namespace.register(scoped_object)

      expect(scoped_object.namespace).to be(namespace)

      keys = [
        "scoped_name",
        "::SomeNamespace::scoped_name",
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
          ["scoped_name"]
        ]

        keys.each do |key|
          expect(namespace.lookup(key)).to be(scoped_object)
          expect(namespace.lookup!(key)).to be(scoped_object)
        end
      end

      context "with parent namespaces" do
        let(:grandparent_namespace) do
          described_class.new("GrandparentPrefix1::GrandParentPrefix2::GrandparentNamespace")
        end

        let(:parent_namespace) do
          described_class.new("ParentNamespace", parent_namespace: grandparent_namespace)
        end

        it "registers the object and it can be found again" do
          namespace.register(scoped_object)

          keys = [
            scoped_object.scoped_name,
            scoped_object.scoped_short_name,
            scoped_object.scoped_full_name,
            scoped_object.scoped_path,
            scoped_object.scoped_short_path,
            scoped_object.scoped_full_path
          ].uniq

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
  end
end
