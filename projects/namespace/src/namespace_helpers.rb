require_relative "is_namespace"

module Foobara
  class Namespace
    module NamespaceHelpers
      module ScopedDefaultNamespace
        include Concern

        inherited_overridable_class_attr_accessor :scoped_default_namespace
      end

      module SubclassesAreNamespaces
        include Concern

        module ClassMethods
          def inherited(subclass)
            super

            subclass.extend ::Foobara::Scoped

            NamespaceHelpers.foobara_autoset_namespace(subclass, default_namespace: scoped_default_namespace)
            NamespaceHelpers.foobara_autoset_scoped_path(subclass)

            subclass.extend ::Foobara::Namespace::IsNamespace
          end
        end
      end

      module AutoRegisterSubclasses
        include Concern

        module ClassMethods
          def inherited(subclass)
            super

            subclass.extend ::Foobara::Scoped

            NamespaceHelpers.foobara_autoset_namespace(subclass, default_namespace: scoped_default_namespace)
            NamespaceHelpers.foobara_autoset_scoped_path(subclass)

            if subclass.scoped_namespace
              if subclass.is_a?(Foobara::Namespace::IsNamespace)
                subclass.foobara_parent_namespace = subclass.scoped_namespace
              end

              subclass.scoped_namespace.foobara_register(subclass)
            end
          end
        end
      end

      module AutoRegisterInstances
        include Concern

        def initialize(*, **, &)
          if Foobara::Util.super_method_takes_parameters?(self, AutoRegisterInstances, __method__)
            super
          else
            # :nocov:
            super()
            # :nocov:
          end

          ns = scoped_namespace || self.class.scoped_default_namespace
          ns&.foobara_register(self)
        end
      end

      module InstancesAreNamespaces
        include Concern

        include ::Foobara::Namespace::IsNamespace

        def initialize(*, **, &)
          if Foobara::Util.super_method_takes_parameters?(self, InstancesAreNamespaces, __method__)
            super
          else
            super()
          end

          parent_namespace = scoped_namespace || self.class.scoped_default_namespace
          NamespaceHelpers.initialize_foobara_namespace(self, parent_namespace:)
        end
      end

      class << self
        def initialize_foobara_namespace(namespace, scoped_name_or_path = nil, parent_namespace: nil)
          unless namespace.scoped_path_set?
            scoped_name_or_path = scoped_name_or_path.to_s if scoped_name_or_path.is_a?(::Symbol)

            if scoped_name_or_path.is_a?(::String)
              namespace.scoped_name = scoped_name_or_path
            elsif scoped_name_or_path.is_a?(::Array)
              namespace.scoped_path = scoped_name_or_path
            end
          end

          if namespace.scoped_path_set? && parent_namespace
            namespace.foobara_parent_namespace = parent_namespace
          end
        end

        def foobara_namespace!(object, scoped_path: nil, ignore_modules: nil)
          object.extend ::Foobara::Scoped

          object.scoped_ignore_modules = ignore_modules if ignore_modules
          object.scoped_path = scoped_path if scoped_path

          object.extend ::Foobara::Namespace::IsNamespace
        end

        def foobara_subclasses_are_namespaces!(klass, default_parent: nil, autoregister: nil)
          klass.include ScopedDefaultNamespace unless klass < ScopedDefaultNamespace
          klass.scoped_default_namespace = default_parent if default_parent

          klass.include SubclassesAreNamespaces unless klass < SubclassesAreNamespaces

          if autoregister
            foobara_autoregister_subclasses(klass)
          end
        end

        def foobara_instances_are_namespaces!(klass, default_parent: nil, autoregister: nil)
          klass.include ScopedDefaultNamespace unless klass < ScopedDefaultNamespace
          klass.scoped_default_namespace = default_parent if default_parent
          klass.include InstancesAreNamespaces unless klass < InstancesAreNamespaces

          if autoregister
            klass.include AutoRegisterInstances
          end
        end

        def foobara_autoregister_subclasses(klass, default_namespace: nil)
          klass.include ScopedDefaultNamespace unless klass < ScopedDefaultNamespace
          klass.scoped_default_namespace = default_namespace if default_namespace
          klass.include AutoRegisterSubclasses unless klass < AutoRegisterSubclasses
        end

        def foobara_autoset_namespace(mod, default_namespace: nil)
          return if mod.scoped_namespace

          parent_mod = Util.module_for(mod)

          while parent_mod
            if parent_mod.is_a?(Foobara::Namespace::IsNamespace)
              mod.scoped_namespace = parent_mod
              return
            else
              parent_mod = Util.module_for(parent_mod)
            end
          end

          mod.scoped_namespace = default_namespace if default_namespace
        end

        def foobara_autoset_scoped_path(mod)
          return if mod.scoped_path_set?

          scoped_path = mod.name.split("::")

          adjusted_scoped_path = []

          next_mod = Object

          while next_mod
            path_part = scoped_path.shift

            break unless path_part

            next_mod = Util.constant_value(next_mod, path_part)

            if next_mod.is_a?(IsNamespace) && next_mod != mod
              adjusted_scoped_path = []
              next
            end

            adjusted_scoped_path << path_part unless mod.scoped_namespace&.scoped_ignore_module?(next_mod)
          end

          mod.scoped_path_autoset = true
          mod.scoped_path = adjusted_scoped_path
        end
      end

      def foobara_namespace!(scoped_path: nil, ignore_modules: nil)
        NamespaceHelpers.foobara_namespace!(self, scoped_path:, ignore_modules:)
      end

      def foobara_subclasses_are_namespaces!(default_parent: nil, autoregister: false)
        NamespaceHelpers.foobara_subclasses_are_namespaces!(self, default_parent:, autoregister:)
      end

      def foobara_instances_are_namespaces!(default_parent: nil, autoregister: false)
        NamespaceHelpers.foobara_instances_are_namespaces!(self, default_parent:, autoregister:)
      end

      def foobara_autoregister_subclasses(default_namespace: nil)
        NamespaceHelpers.foobara_autoregister_subclasses(self, default_namespace:)
      end

      def foobara_root_namespace!(ignore_modules: nil)
        foobara_namespace!(scoped_path: [], ignore_modules:)
      end

      def foobara_autoset_namespace!(default_namespace: nil)
        NamespaceHelpers.foobara_autoset_namespace(self, default_namespace:)
      end

      def foobara_autoset_scoped_path!
        NamespaceHelpers.foobara_autoset_scoped_path(self)
      end
    end
  end
end
