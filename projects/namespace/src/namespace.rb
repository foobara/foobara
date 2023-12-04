module Foobara
  class Namespace
    class << self
      def autoregister(mod, default_parent: nil)
        parent_mod = Util.module_for(mod)
        parent_namespace = nil

        while parent_mod
          if parent_mod
            if parent_mod.is_a?(Foobara::Namespace::IsNamespace)
              parent_namespace = parent_mod
              break
            else
              parent_mod = Util.module_for(parent_mod)
            end
          end
        end

        parent_namespace ||= default_parent

        unless parent_namespace
          # :nocov:
          raise "No parent namespace found for #{mod}"
          # :nocov:
        end

        mod.scoped_name = mod.name.gsub(/^#{parent_namespace.name}::/, "")

        parent_namespace.register(mod)
      end
    end

    include IsNamespace

    class NotFoundError < StandardError; end

    def initialize(scoped_name_or_path, accesses: [], parent_namespace: nil)
      initialize_foobara_namespace(scoped_name_or_path, accesses:, parent_namespace:)
    end
  end
end
