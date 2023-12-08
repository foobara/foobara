module RspecHelpers
  module StubClass
    module ClassMethods
      def stub_class(name, superclass = nil, which: :class, &block)
        name = name.to_s if name.is_a?(::Symbol)

        unless metadata.key?(:foobara_stubbed_modules)
          set = metadata[:foobara_stubbed_modules] = Set.new

          after do
            names = set.sort_by { |s| -s.count(":") }

            names.each do |module_name|
              Foobara::Util.remove_constant(module_name)
            end

            set.clear
          end
        end

        metadata[:foobara_stubbed_modules] << name

        Foobara::Util.make_class(name, superclass, which:, &block)
      end

      def stub_module(name, &)
        stub_class(name, which: :module, &)
      end
    end

    def stub_class(name, superclass = nil, &)
      self.class.stub_class(name, superclass, &)
    end

    def stub_module(name, &)
      self.class.stub_module(name, &)
    end
  end
end

RSpec.configure do |c|
  c.include RspecHelpers::StubClass
  c.extend RspecHelpers::StubClass::ClassMethods
end
