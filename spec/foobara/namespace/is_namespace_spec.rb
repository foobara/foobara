RSpec.describe Foobara::Namespace::IsNamespace do
  let(:namespace) do
    Object.new.tap do |o|
      class << o
        def scoped_path
          ["SomeNamespace"]
        end
      end

      o.extend described_class
    end
  end

  describe "#register" do
    let(:scoped_object) { Object.new }
    let(:scoped_name) { "scoped_name" }
    let(:parent_namespace) { nil }

    before do
      scoped_object.extend(Foobara::Scoped)
      scoped_object.scoped_name = scoped_name
    end

    it "registers the object and it can be found again" do
      expect(namespace.scoped_path).to eq(["SomeNamespace"])
      expect(namespace.scoped_name).to eq("SomeNamespace")
      expect(namespace.scoped_full_name).to eq("::SomeNamespace")

      namespace.foobara_register(scoped_object)
      expect(scoped_object.scoped_namespace).to be(namespace)

      expect(scoped_object.scoped_short_path).to eq([scoped_name])
      expect(scoped_object.scoped_full_path).to eq(["SomeNamespace", scoped_name])
      expect(scoped_object.scoped_full_name).to eq("::SomeNamespace::#{scoped_name}")

      keys = [
        "scoped_name",
        ["scoped_name"]
      ]

      keys.each do |key|
        expect(namespace.foobara_lookup(key)).to be(scoped_object)
        expect(namespace.foobara_lookup!(key)).to be(scoped_object)
      end
    end
  end

  describe "#lookup" do
    context "when using instance of categories" do
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
          namespace.foobara_add_category_for_instance_of(:class1, class1)
          namespace.foobara_add_category_for_instance_of(:class2, class2)
        end

        context "when an object is registered" do
          before do
            namespace.foobara_register(object1)
          end

          context "when looking up with matching lookup_class1 method and lookup method" do
            it "returns the object" do
              expect(namespace.foobara_lookup_class1(scoped_name)).to be(object1)
              expect(namespace.foobara_lookup_class1!(scoped_name)).to be(object1)
              expect(namespace.foobara_lookup(scoped_name)).to be(object1)
              expect(namespace.foobara_lookup!(scoped_name)).to be(object1)
            end
          end
        end
      end
    end
  end
end
