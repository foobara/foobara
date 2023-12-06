module RspecHelpers
  module StubClass
    class << self
      def make_class(name, &)
        # rubocop:disable Security/Eval, Style/DocumentDynamicEvalDefinition
        eval(<<~RUBY, binding, __FILE__, __LINE__ + 1)
          class ::#{name}
          end
        RUBY

        klass = Object.const_get(name)
        klass.class_eval(&)
        klass
      end
    end

    module ClassMethods
      def stub_class(name, &)
        StubClass.make_class(name, &).tap do
          after do
            Object.send(:remove_const, name)
          end
        end
      end
    end

    def stub_class(name, &)
      StubClass.make_class(name, &).tap do
        self.class.after do
          Object.send(:remove_const, name)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include RspecHelpers::StubClass
  c.extend RspecHelpers::StubClass::ClassMethods
end
