RSpec.describe Foobara::Namespace::NamespaceHelpers do
  describe ".foobara_instances_are_namespaces!" do
    let(:instance) { klass.new(name) }

    let(:default_parent) { Foobara::Namespace.new("ParentNamespace") }
    let(:klass) do
      stub_class("SomeClass") do
        attr_reader :name

        def initialize(name)
          @name = name
          super
        end

        def scoped_path
          [name]
        end
      end
    end
    let(:autoregister) { true }
    let(:name) { "some_name" }

    before do
      klass.foobara_instances_are_namespaces!(default_parent:, autoregister:)
    end

    it "sets up the instance as expected" do
      expect(instance).to be_a(Foobara::Namespace::IsNamespace)
      expect(instance.foobara_parent_namespace).to eq(default_parent)
    end

    context "when inherited" do
      let(:subclass) { stub_class "SomeSubclass", klass }
      let(:instance) { subclass.new(name) }

      it "sets up the instance as expected" do
        expect(instance).to be_a(subclass)
        expect(instance).to be_a(Foobara::Namespace::IsNamespace)
        expect(instance.foobara_parent_namespace).to eq(default_parent)
      end
    end
  end

  describe ".update_children_with_new_parent" do
    let(:parent_module) do
      stub_module("ParentModule")
    end
    let(:child_module) do
      parent_module
      stub_module("ParentModule::ChildModule") do
        extend Foobara::Scoped

        foobara_autoset_scoped_path!
        Foobara::GlobalDomain.foobara_register(self)
      end
    end

    context "when retroactively making parent module a namespace" do
      it "updates the scoped_path" do
        expect {
          parent_module.foobara_namespace!
          parent_module.foobara_autoset_scoped_path!
        }.to change(child_module, :scoped_path).from(["ParentModule", "ChildModule"]).to(["ChildModule"])
      end
    end
  end
end
