RSpec.describe Foobara::Concern do
  context "when inheriting through another concern" do
    let(:root_concern) do
      Module.new do
        include Foobara::Concern

        const_set(:ClassMethods, Module.new do
                                   def foo?
                                     true
                                   end
                                 end)

        on_include do
          singleton_class.define_method :name_under do
            Foobara::Util.underscore(name)
          end
        end
      end
    end

    let(:sub_concern) do
      r = root_concern

      stub_module "SubConcern" do
        include Foobara::Concern
        include r
      end
    end

    let(:klass) do
      c = sub_concern

      stub_class :SomeClass do
        include c
      end
    end

    it "passes class methods and effects of on_include through" do
      expect(klass.singleton_class.ancestors.map(&:name)).to include("SubConcern::ClassMethods")
      expect(klass.foo?).to be(true)
      expect(klass.name_under).to eq("some_class")
    end
  end
end
