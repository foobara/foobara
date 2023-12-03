RSpec.describe Foobara::Namespace do
  describe "#register" do
    let(:namespace_name) { "SomeNamespace" }
    let(:namespace) { described_class.new(namespace_name, parent_namespace:) }
    let(:scoped_object) { Object.new }
    let(:scoped_name) { "scoped_name" }
    let(:parent_namespace) { nil }

    before do
      scoped_object.extend(Foobara::Scoped)
      scoped_object.scoped_name = scoped_name
    end

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

  describe "#lookup" do
    context "when using instance of categories" do
      let(:namespace) { described_class.new("SomeNamespace") }

      let(:base_class) do
        Class.new do
          include Foobara::Scoped

          attr_accessor :name

          def initialize(name)
            self.name = name
          end

          def scoped_path
            ["some_scoped_name"]
          end
        end
      end

      let(:scoped_name) { "some_scoped_name" }

      let(:class1) { Class.new(base_class) }
      let(:class2) { Class.new(base_class) }
      let(:class3) { Class.new(base_class) }

      let(:object1) { class1.new("object1") }
      let(:object2) { class2.new("object2") }
      let(:object3) { class3.new("object3") }

      let(:objects) { [object1, object2, object3] }

      context "when there are two categories" do
        before do
          namespace.add_category_for_instance_of(:class1, class1)
          namespace.add_category_for_instance_of(:class2, class2)
        end

        it "has expected respond_to? results" do
          expect(namespace).to respond_to(:lookup_class1)
          expect(namespace).to respond_to(:lookup_class1!)
          expect(namespace).to respond_to(:lookup_class2)
          expect(namespace).to respond_to(:lookup_class2!)
          expect(namespace).to_not respond_to(:lookup_class3)
          expect(namespace).to_not respond_to(:lookup_class3!)
        end

        context "when an object is registered" do
          before do
            namespace.register(object1)
          end

          context "when looking up with matching lookup_class1 method and lookup method" do
            it "returns the object" do
              expect(namespace.lookup_class1(scoped_name)).to be(object1)
              expect(namespace.lookup_class1!(scoped_name)).to be(object1)
              expect(namespace.lookup(scoped_name)).to be(object1)
              expect(namespace.lookup!(scoped_name)).to be(object1)
            end
          end

          context "when looking up with non-matching lookup_class2 method" do
            it "does not return the object" do
              expect(namespace.lookup_class2(scoped_name)).to be_nil
              expect {
                namespace.lookup_class2!(scoped_name)
              }.to raise_error(Foobara::Namespace::NotFoundError)
            end
          end

          context "when all objects registered" do
            before do
              namespace.register(object2)
              namespace.register(object3)
            end

            it "can fetch the proper items with different lookup_* methods" do
              expect(namespace.lookup_class1(scoped_name)).to be(object1)
              expect(namespace.lookup_class2(scoped_name)).to be(object2)
            end
          end
        end
      end
    end

    context "when using subclass of categories" do
      let(:namespace) { described_class.new("SomeNamespace") }

      let(:base_class) do
        Class.new do
          extend Foobara::Scoped

          class << self
            def scoped_path
              ["some_scoped_name"]
            end
          end
        end
      end

      let(:scoped_name) { "some_scoped_name" }

      let(:class1) { Class.new(base_class) }
      let(:class2) { Class.new(base_class) }
      let(:class3) { Class.new(base_class) }

      let(:class_a) { Class.new(class1) }
      let(:class_b) { Class.new(class2) }
      let(:class_c) { Class.new(class3) }

      context "when there are two categories" do
        before do
          namespace.add_category_for_subclass_of(:class1, class1)
          namespace.add_category_for_subclass_of(:class2, class2)
        end

        context "when an object is registered" do
          before do
            namespace.register(class_a)
          end

          context "when looking up with matching lookup_class1 method and lookup method" do
            it "returns the object" do
              expect(namespace.lookup_class1(scoped_name)).to be(class_a)
              expect(namespace.lookup_class1!(scoped_name)).to be(class_a)
              expect(namespace.lookup(scoped_name)).to be(class_a)
              expect(namespace.lookup!(scoped_name)).to be(class_a)
            end
          end

          context "when looking up with non-matching lookup_class2 method" do
            it "does not return the object" do
              expect(namespace.lookup_class2(scoped_name)).to be_nil
              expect {
                namespace.lookup_class2!(scoped_name)
              }.to raise_error(Foobara::Namespace::NotFoundError)
            end
          end

          context "when all objects registered" do
            before do
              namespace.register(class_b)
              namespace.register(class_c)
            end

            it "can fetch the proper items with different lookup_* methods" do
              expect(namespace.lookup_class1(scoped_name)).to be(class_a)
              expect(namespace.lookup_class2(scoped_name)).to be(class_b)
            end
          end
        end
      end
    end
  end
end
