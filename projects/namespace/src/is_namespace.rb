require_relative "scoped"

module Foobara
  class Namespace
    module IsNamespace
      include Scoped

      def foobara_parent_namespace=(namespace)
        self.scoped_namespace = namespace
        scoped_namespace.foobara_children << self if namespace
      end

      def foobara_add_category(symbol, proc)
        @foobara_categories = foobara_categories.merge(symbol.to_sym => proc)
      end

      def foobara_add_category_for_instance_of(symbol, klass)
        foobara_add_category(symbol, proc { is_a?(klass) })
      end

      def foobara_add_category_for_subclass_of(symbol, klass)
        foobara_add_category(symbol, proc { self < klass })
      end

      def foobara_categories
        @foobara_categories ||= foobara_parent_namespace&.foobara_categories || {}
      end

      def foobara_registry
        @foobara_registry ||= Foobara::Namespace::PrefixlessRegistry.new
      end

      def foobara_children
        @foobara_children ||= []
      end

      def foobara_root_namespace
        ns = self

        ns = ns.foobara_parent_namespace until ns.foobara_root?

        ns
      end

      def foobara_root?
        foobara_parent_namespace.nil?
      end

      def foobara_register(scoped)
        begin
          foobara_registry.register(scoped)
        rescue PrefixlessRegistry::RegisteringScopedWithPrefixError,
               BaseRegistry::WouldMakeRegistryAmbiguousError => e
          _upgrade_registry(e)
          return foobara_register(scoped)
        end

        # awkward??
        scoped.scoped_namespace = self
      end

      def foobara_lookup(path, absolute: false, filter: nil)
        if path.is_a?(::Symbol)
          path = path.to_s
        end

        if path.is_a?(::String)
          path = path.split("::")
        end

        if path[0] == ""
          return foobara_root_namespace.foobara_lookup(path[(foobara_root_namespace.scoped_path.size + 1)..],
                                                       absolute: true, filter:)
        end

        scoped = foobara_registry.lookup(path, filter)
        return scoped if scoped

        matching_child = nil
        matching_child_score = 0

        to_consider = absolute ? foobara_children : [self, *foobara_children]

        to_consider.each do |namespace|
          match_count = namespace._path_start_match_count(path)

          if match_count > matching_child_score
            matching_child = namespace
            matching_child_score = match_count
          end
        end

        if matching_child
          scoped = matching_child.foobara_lookup(path[matching_child_score..], absolute: true, filter:)
          return scoped if scoped
        end

        unless absolute
          foobara_parent_namespace&.foobara_lookup(path, filter:)
        end
      end

      def foobara_parent_namespace
        scoped_namespace
      end

      def foobara_lookup!(name, filter: nil)
        object = foobara_lookup(name, filter:)

        unless object
          # :nocov:
          raise NotFoundError, "Could not find #{name}"
          # :nocov:
        end

        object
      end

      def method_missing(method_name, *)
        filter, bang = _filter_from_method_name(method_name)

        if filter
          if bang
            foobara_lookup!(*, filter:)
          else
            foobara_lookup(*, filter:)
          end
        else
          # :nocov:
          super
          # :nocov:
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        !!_filter_from_method_name(method_name) || super
      end

      private

      def _filter_from_method_name(method_name)
        match = method_name.to_s.match(/^lookup_(\w+)(!)?$/)

        if match
          filter = foobara_categories[match[1].to_sym]
          if filter
            bang = !match[2].nil?

            [filter, bang]
          end
        end
      end

      def _upgrade_registry(error)
        new_registry_class = case error
                             when Foobara::Namespace::PrefixlessRegistry::RegisteringScopedWithPrefixError
                               Foobara::Namespace::UnambiguousRegistry
                             when Foobara::Namespace::BaseRegistry::WouldMakeRegistryAmbiguousError
                               Foobara::Namespace::AmbiguousRegistry
                             end

        old_registry = foobara_registry

        @foobara_registry = new_registry_class.new

        old_registry.each_scoped { |s| foobara_registry.register(s) }
      end

      protected

      def _path_start_match_count(path)
        count = 0

        scoped_path.each.with_index do |part, i|
          if part == path[i]
            count += 1
          else
            break
          end
        end

        count
      end
    end
  end
end
