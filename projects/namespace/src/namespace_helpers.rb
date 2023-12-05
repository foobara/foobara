# TODO: refactor initialize extended inherited into modules os that inheritance works

module Foobara
  module Namespace
    module NamespaceHelpers
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
          klass.singleton_class.define_method :inherited do |subclass|
            subclass.extend ::Foobara::Scoped

            foobara_autoset_namespace(subclass, default_parent:)
            foobara_autoset_scoped_path(subclass)

            subclass.extend ::Foobara::Namespace::IsNamespace

            subclass.parent_namespace = mod.namespace if mod.namespace
            mod.namespace&.register(mod)

            super(subclass)
          end

          foobara_autoregister_subclasses(klass)
        end

        def foobara_autoregister_subclasses(klass)
          klass.singleton_class.define_method :inherited do |subclass|
            if mod.namespace
              subclass.parent_namespace = mod.namespace
              mod.namespace&.register(mod)
            end

            super(subclass)
          end
        end

        def foobara_autoset_namespace(mod, default: nil)
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

          mod.namespace = default if default
        end

        def foobara_autoset_scoped_path(mod)
          begin
            mod.scoped_path
            return
          rescue Scoped::NoScopedPathSetError
          end

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

          klass.define_method :initialize do |*args, **opts, &block|
            initialize_foobara_namespace(symbol, accesses: [], parent_namespace: default_parent)
            super(*args, **opts, &block)
          end
        end
      end

      def foobara_namespace!(scoped_path: nil, ignore_modules: nil)
        NamespaceHelpers.foobara_namespace!(self, scoped_path:, ignore_modules:)
      end

      def foobara_subclasses_are_namespaces!(klass, default_parent: nil)
        NamespaceHelpers.foobara_subclasses_are_namespaces!(klass, default_parent:)
      end

      def foobara_autoregister_subclasses(klass)
        NamespaceHelpers.foobara_autoregister_subclasses(klass)
      end

      def foobara_instances_are_namespaces!(klass, default_parent: nil)
        NamespaceHelpers.foobara_instances_are_namespaces!(klass, default_parent:)
      end
    end
  end
end
