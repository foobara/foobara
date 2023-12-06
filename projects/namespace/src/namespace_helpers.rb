# TODO: refactor initialize extended inherited into modules os that inheritance works

module Foobara
  class Namespace
    module NamespaceHelpers
      module SubclassesAreNamespaces
        attr_accessor :scoped_default_namespace

        def inherited(subclass)
          super

          subclass.extend ::Foobara::Scoped

          NamespaceHelpers.foobara_autoset_namespace(subclass, default_namespace: scoped_default_namespace)
          NamespaceHelpers.foobara_autoset_scoped_path(subclass)

          subclass.extend ::Foobara::Namespace::IsNamespace
        end
      end

      module AutoRegisterSubclasses
        # TODO: dry this up somehow?
        attr_accessor :scoped_default_namespace

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

      module AutoRegisterInstances
        def initialize(*, **, &)
          if self.class.superclass == Object
            super()
          else
            # :nocov:
            super
            # :nocov:
          end

          ns = scoped_namespace || self.class.scoped_default_namespace

          ns&.foobara_register(self)
        end
      end

      module InstancesAreNamespaces
        # TODO: dry this up somehow?
        class << self
          def included(mod)
            class << mod
              attr_accessor :scoped_default_namespace
            end

            super
          end
        end

        def initialize(*, **, &)
          self.class.superclass == Object ? super() : super

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
            else
              # :nocov:
              raise "Invalid scoped name or path and for #{namespace} "
              # :nocov:
            end
          end

          if parent_namespace
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
          klass.extend SubclassesAreNamespaces
          klass.scoped_default_namespace = default_parent

          if autoregister
            foobara_autoregister_subclasses(klass)
          end
        end

        def foobara_instances_are_namespaces!(klass, default_parent: nil, autoregister: nil)
          klass.include ::Foobara::Namespace::IsNamespace
          klass.include InstancesAreNamespaces

          klass.scoped_default_namespace = default_parent if default_parent

          if autoregister
            klass.include AutoRegisterInstances
          end
        end

        def foobara_autoregister_subclasses(klass, default_namespace: nil)
          klass.extend AutoRegisterSubclasses
          klass.scoped_default_namespace = default_namespace if default_namespace
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
    end
  end
end
