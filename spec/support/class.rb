module RspecHelpers
  module StubClass
    module ClassMethods
      def stub_class(name, which: :class, &)
        # rubocop:disable Security/Eval, Style/DocumentDynamicEvalDefinition
        eval(<<~RUBY, binding, __FILE__, __LINE__ + 1)
          #{which} ::#{name}
          end
        RUBY
        # rubocop:enable Security/Eval, Style/DocumentDynamicEvalDefinition

        after do
          Object.send(:remove_const, name)
        end

        klass = Object.const_get(name)
        klass.class_eval(&)
        klass
      end

      def stub_module(name, &)
        stub_class(name, which: :module, &)
      end
    end

    def stub_class(name, &)
      self.class.stub_class(name, &)
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
