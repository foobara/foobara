module Foobara
  module Concern
    class << self
      def included(concern)
        concern.singleton_class.define_method :included do |klass|
          if concern.const_defined?(:ClassMethods)
            klass.extend(concern.const_get(:ClassMethods))
          end
        end
      end
    end
  end
end
