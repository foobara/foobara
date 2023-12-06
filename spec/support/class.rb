module RspecHelpers
  module StubClass
    module ClassMethods
      def stub_class(name, superclass = nil, which: :class, &)
        name = name.to_sym

        if superclass.is_a?(Class)
          superclass = superclass.name
        end

        superclass ||= :Object

        # rubocop:disable Security/Eval, Style/DocumentDynamicEvalDefinition
        eval(<<~RUBY, binding, __FILE__, __LINE__ + 1)
          #{which} ::#{name} < ::#{superclass}
          end
        RUBY
        # rubocop:enable Security/Eval, Style/DocumentDynamicEvalDefinition

        unless metadata.key?(:foobara_stubbed_modules)
          metadata[:foobara_stubbed_modules] = Set.new

          after do
            self.class.metadata[:foobara_stubbed_modules].each do |module_name|
              Object.send(:remove_const, module_name)
            end

            self.class.metadata[:foobara_stubbed_modules] = Set.new
          end
        end

        metadata[:foobara_stubbed_modules] << name

        klass = Object.const_get(name)
        klass.class_eval(&)
        klass
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
