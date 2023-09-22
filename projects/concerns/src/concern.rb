module Foobara
  module Concern
    module IsConcern
      def included(klass)
        if Concern.foobara_concern?(klass)
          if const_defined?(:ClassMethods, false)
            unless klass.const_defined?(:ClassMethods, false)
              class_methods_module_name = if klass.name.present?
                                            "#{klass.name}::ClassMethods"
                                          end

              klass.const_set(:ClassMethods, Module.new do
                                               if class_methods_module_name.present?
                                                 singleton_class.define_method :name do
                                                   class_methods_module_name
                                                 end
                                               end
                                             end)
            end

            klass.const_get(:ClassMethods, false).include(const_get(:ClassMethods, false))
          end
        elsif const_defined?(:ClassMethods, false)
          klass.extend(const_get(:ClassMethods, false))
        end

        has_include_to_apply = klass.ancestors.select do |mod|
          Concern.foobara_concern?(mod) && mod.has_foobara_on_include_block?
        end

        has_include_to_apply.reverse.each do |concern|
          klass.class_eval(&concern.foobara_on_include_block)
        end

        super
      end

      def has_foobara_on_include_block?
        !!@foobara_on_include
      end

      def foobara_on_include_block
        @foobara_on_include
      end

      def on_include(&block)
        @foobara_on_include = block
      end
    end

    class << self
      def included(concern)
        concern.extend(IsConcern)
      end

      def foobara_concern?(mod)
        mod.singleton_class < IsConcern
      end
    end
  end
end
