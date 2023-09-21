module Foobara
  module Concern
    module InstallClassMethods
      def included(klass)
        if const_defined?(:ClassMethods)
          klass.extend(const_get(:ClassMethods))
        end

        if @foobara_on_include
          klass.class_eval(&@foobara_on_include)
        end

        super
      end

      def on_include(&block)
        @foobara_on_include = block
      end
    end

    class << self
      def included(concern)
        concern.extend(InstallClassMethods)
      end
    end
  end
end
