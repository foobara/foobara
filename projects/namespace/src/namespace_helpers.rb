# TODO: refactor initialize extended inherited into modules os that inheritance works

module Foobara
  class Namespace
    module NamespaceHelpers
      module SubclassesAreNamespaces
        attr_accessor :default_namespace

        def inherited(subclass)
          super

          subclass.extend ::Foobara::Scoped

          NamespaceHelpers.foobara_autoset_namespace(subclass, default_namespace:)
          NamespaceHelpers.foobara_autoset_scoped_path(subclass)

          subclass.extend ::Foobara::Namespace::IsNamespace
        end
      end

      module AutoRegisterSubclasses
        # TODO: dry this up somehow?
        attr_accessor :default_namespace

        def inherited(subclass)
          super

          if !subclass.namespace && default_namespace
            subclass.namespace = default_namespace
          end

          if subclass.namespace
            if subclass.is_a?(Foobara::Namespace::IsNamespace)
              subclass.parent_namespace = subclass.namespace
            end

            subclass.namespace&.register(subclass)
          end
        end
      end

      module InstancesAreNamespaces
        def initialize(*, **, &)
          parent_namespace = namespace || default_namespace
          initialize_foobara_namespace(symbol, accesses: [], parent_namespace:)
          super
        end
      end

      class << self
        # *1. extend a module/root or global namespace (Foobara)
        # *2. all subclasses should be namespaces and autoregistered (Org/Domain/Command)
        # *3. all instances are namespaces (Type)
        # 4. explicit registration (Max)
        # *5. not a namespace but should be autoregistered (Error)

        def foobara_namespace!(object, scoped_path: nil, ignore_modules: nil)
          object.extend ::Foobara::Scoped

          object.ignore_modules = ignore_modules if ignore_modules
          object.scoped_path = scoped_path if scoped_path

          object.extend ::Foobara::Namespace::IsNamespace
        end

        def foobara_subclasses_are_namespaces!(klass, default_parent: nil)
          klass.extend SubclassesAreNamespaces
          klass.default_namespace = default_parent
          foobara_autoregister_subclasses(klass)
        end

        def foobara_autoregister_subclasses(klass, default_namespace: nil)
          klass.extend AutoRegisterSubclasses
          klass.default_namespace = default_namespace if default_namespace
        end

        def foobara_autoset_namespace(mod, default_namespace: nil)
          return if mod.namespace

          parent_mod = Util.module_for(mod)

          while parent_mod
            if parent_mod.is_a?(Foobara::Namespace::IsNamespace)
              mod.namespace = parent_mod
              return
            else
              parent_mod = Util.module_for(parent_mod)
            end
          end

          mod.namespace = default_namespace if default_namespace
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

            if next_mod
              if next_mod.is_a?(IsNamespace) && next_mod != mod
                adjusted_scoped_path = []
                next
              end
            else
              adjusted_scoped_path += [path_part, *scoped_path]
              break
            end

            if mod.is_a?(IsNamespace)
              adjusted_scoped_path << path_part unless mod.ignore_module?(next_mod)
            elsif mod.is_a?(Scoped)
              adjusted_scoped_path << path_part unless mod.namespace&.ignore_module?(next_mod)
            else
              adjusted_scoped_path << path_part
            end
          end

          mod.scoped_path = adjusted_scoped_path
        end

        def foobara_instances_are_namespaces!(klass, default_parent: nil)
          klass.include ::Foobara::Namespace::IsNamespace
          klass.include InstancesAreNamespaces

          if default_parent
            klass.foobara_scoped_default_namespace = default_parent
          end
        end

        def root_namespace!(mod, scoped_path: [], ignore_modules: nil)
          mod.extend ::Foobara::Scoped

          mod.scoped_path = scoped_path
          mod.ignore_modules = Util.array(ignore_modules) if ignore_modules

          mod.extend ::Foobara::Namespace::IsNamespace
        end
      end

      def foobara_namespace!(scoped_path: nil, ignore_modules: nil)
        NamespaceHelpers.foobara_namespace!(self, scoped_path:, ignore_modules:)
      end

      def foobara_subclasses_are_namespaces!(default_parent: nil)
        NamespaceHelpers.foobara_subclasses_are_namespaces!(self, default_parent:)
      end

      def foobara_autoregister_subclasses(default_namespace)
        NamespaceHelpers.foobara_autoregister_subclasses(self, default_namespace:)
      end

      def foobara_instances_are_namespaces!(default_parent: nil)
        NamespaceHelpers.foobara_instances_are_namespaces!(self, default_parent:)
      end

      def foobara_root_namespace!(scoped_path: [], ignore_modules: nil)
        NamespaceHelpers.root_namespace!(self, scoped_path:, ignore_modules:)
      end
    end
  end
end
