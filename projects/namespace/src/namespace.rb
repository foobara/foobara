module Foobara
  class Namespace
    class << self
      def autoregister(mod, default_parent: nil)
        # TODO: eliminate parent_namespace or make it an alias of namespace!!
        unless mod.namespace
          parent_mod = Util.module_for(mod)

          while parent_mod
            if parent_mod.is_a?(Foobara::Namespace::IsNamespace)
              mod.namespace = parent_mod
              break
            else
              parent_mod = Util.module_for(parent_mod)
            end
          end

          mod.namespace ||= default_parent
        end

        scoped_path_already_set = begin
          mod.scoped_path
          true
        rescue Scoped::NoScopedPathSetError
          false
        end

        unless scoped_path_already_set
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

        binding.pry if mod.name =~ /OrgA::DomainA::CommandA$/

        if mod.is_a?(IsNamespace)
          mod.parent_namespace = mod.namespace
        else
          mod.namespace&.register(mod)
        end
      end
    end

    include IsNamespace

    class NotFoundError < StandardError; end

    def initialize(scoped_name_or_path, accesses: [], parent_namespace: nil)
      initialize_foobara_namespace(scoped_name_or_path, accesses:, parent_namespace:)
    end
  end
end
