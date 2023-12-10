module Foobara
  module Concern
    # TODO: there seems to be a bug when extending classes. They do not get inheritance for free with
    # this module as would be expected.
    module IsConcern
      def included(klass)
        # If behavior is defined in Concern A and then included into Concern B, we need to make sure
        # that when B is included it's also as if A were included.
        # ClassMethods on A should exist on any object's class that included B.
        # Any code-snippets to be ran when A is included should also be ran if B is included.
        if Concern.foobara_concern?(klass)
          if const_defined?(:ClassMethods, false)
            Concern.foobara_class_methods_module_for(klass).include(const_get(:ClassMethods, false))
          end
        else
          if const_defined?(:ClassMethods, false)
            klass.extend(const_get(:ClassMethods, false))
          end

          ancestors.select { |mod| Concern.foobara_concern?(mod) }.reverse.each do |concern|
            concern.instance_variable_get("@inherited_overridable_class_attr_accessors")&.each do |name|
              var_name = "@#{name}"
              klass.instance_variable_set(var_name, klass.instance_variable_get(var_name))
            end

            if concern.has_foobara_on_include_block?
              klass.class_eval(&concern.foobara_on_include_block)
            end
          end
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

      def inherited_overridable_class_attr_accessor(*names)
        @inherited_overridable_class_attr_accessors ||= []
        @inherited_overridable_class_attr_accessors += names

        Concern.foobara_class_methods_module_for(self).module_eval do
          names.each do |name|
            var_name = "@#{name}"

            define_method name do
              if instance_variable_defined?(var_name)
                instance_variable_get(var_name)
              else
                superclass.send(name)
              end
            end

            attr_writer name
          end
        end
      end
    end

    class << self
      def included(concern)
        concern.extend(IsConcern)
      end

      def foobara_concern?(mod)
        mod.singleton_class < IsConcern
      end

      def foobara_class_methods_module_for(klass)
        unless klass.name
          # :nocov:
          raise "This does not work with anonymous classes"
          # :nocov:
        end

        if klass.const_defined?(:ClassMethods, false)
          klass.const_get(:ClassMethods, false)
        else
          Util.make_module "#{klass.name}::ClassMethods"
        end
      end
    end
  end
end
