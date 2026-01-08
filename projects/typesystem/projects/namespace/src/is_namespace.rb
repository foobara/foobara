require_relative "scoped"

module Foobara
  class Namespace
    module IsNamespace
      include Scoped

      def scoped_clear_caches
        super

        foobara_each(&:scoped_clear_caches)

        if defined?(@foobara_categories)
          if @foobara_categories.empty?
            # :nocov:
            remove_instance_variable(:@foobara_categories)
            # :nocov:
          elsif scoped_namespace
            @foobara_categories = scoped_namespace.foobara_categories.merge(@foobara_categories)
          end
        end
      end

      def foobara_parent_namespace=(namespace)
        self.scoped_namespace = namespace

        if namespace
          if namespace.foobara_children.include?(self)
            # :nocov:
            raise "Already registered on parent"
            # :nocov:
          end

          namespace.foobara_children << self
        end
      end

      def foobara_add_category(symbol, &block)
        @foobara_categories = { symbol.to_sym => block }.merge(foobara_categories)
      end

      def foobara_add_category_for_instance_of(symbol, klass)
        foobara_add_category(symbol) { is_a?(klass) }
      end

      def foobara_add_category_for_subclass_of(symbol, klass)
        foobara_add_category(symbol) { is_a?(::Class) && self < klass }
      end

      def foobara_categories
        @foobara_categories ||= foobara_parent_namespace&.foobara_categories || {}
      end

      def foobara_category_symbol_for(object)
        foobara_categories.each_pair do |symbol, block|
          return symbol if object.instance_eval(&block)
        end

        nil
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

      def foobara_depends_on_namespaces
        @foobara_depends_on_namespaces ||= []
      end

      def foobara_root?
        foobara_parent_namespace.nil?
      end

      def to_scoped(scopedish)
        if scopedish.is_a?(::String) || scopedish.is_a?(::Symbol) || scopedish.is_a?(::Array)
          scopedish = foobara_lookup(scopedish)

          unless scopedish
            # :nocov:
            raise ArgumentError, "Cannot unregister non-existent #{scopedish}"
            # :nocov:
          end
        end

        scopedish
      end

      # TODO: make this thread-safe
      def foobara_register(scoped)
        if scoped.scoped_unregistered?
          scoped.scoped_reregistering!
        end

        foobara_registry.register(scoped)

        if scoped.is_a?(Namespace::IsNamespace)
          scoped.foobara_parent_namespace = self
        else
          scoped.scoped_namespace = self
        end

        # TODO: do we really need to clear the whole cache? Why not just the possible
        # impacted keys based on scoped.scoped_path ?
        Namespace.clear_lru_cache!
        Namespace.fire_changed!

        if scoped.unregistered_foobara_manifest_reference
          scoped.unregistered_foobara_manifest_reference = nil
        end

        if scoped.respond_to?(:foobara_on_register)
          scoped.foobara_on_register
        end
      rescue PrefixlessRegistry::RegisteringScopedWithPrefixError,
             BaseRegistry::WouldMakeRegistryAmbiguousError => e
        _upgrade_registry(e)
        foobara_register(scoped)
      end

      def foobara_unregister(scoped)
        scoped = to_scoped(scoped)

        foobara_registry.unregister(scoped)
        foobara_children.delete(scoped)

        scoped.unregistered_foobara_manifest_reference = scoped.foobara_manifest_reference

        scoped.scoped_namespace = nil
        scoped.scoped_unregistered!

        Namespace.clear_lru_cache!
        Namespace.fire_changed!
      end

      def foobara_unregister_all
        foobara_registry.each_scoped do |child|
          foobara_unregister(child)
        end
      end

      def lru_cache
        @lru_cache ||= Namespace.lru_cache
      end

      def foobara_lookup(path, filter: nil, mode: LookupMode::GENERAL)
        LookupMode.validate!(mode)

        path = Namespace.to_registry_path(path)

        lru_cache.cached([self, path, mode, *filter]) do
          visited = Set.new
          foobara_lookup_without_cache(path, filter:, mode:, visited:)
        end
      end

      def foobara_lookup_without_cache(path, filter:, mode:, visited:)
        visited_key = [path, mode, self]
        return nil if visited.include?(visited_key)

        visited << visited_key

        if mode == LookupMode::RELAXED
          scoped = foobara_lookup_without_cache(path, filter:, mode: LookupMode::GENERAL, visited:)

          return scoped if scoped

          candidates = foobara_children.map do |namespace|
            namespace.foobara_lookup_without_cache(path, filter:, mode:, visited:)
          end.compact

          if candidates.size > 1
            # :nocov:
            raise AmbiguousLookupError,
                  "#{path} is ambiguous. Matches the following: #{candidates.map(&:scoped_full_name)}"
            # :nocov:
          end

          scoped = candidates.first ||
                   foobara_parent_namespace&.foobara_lookup_without_cache(path, filter:, mode:, visited:)

          scoped ||= foobara_lookup_without_cache(
            [*scoped_full_path, *path],
            filter:,
            mode: LookupMode::GENERAL,
            visited:
          )

          return scoped
        end

        if path[0] == ""
          if mode == LookupMode::DIRECT
            return nil unless scoped_full_name == ""

            path = path[1..]
          else
            path = path[(foobara_root_namespace.scoped_path.size + 1)..]
          end

          return foobara_lookup_without_cache(path, filter:, mode: LookupMode::ABSOLUTE, visited:)
        end

        root = foobara_root_namespace

        if mode == LookupMode::ABSOLUTE
          [
            root,
            *root.foobara_depends_on_namespaces.map(&:foobara_root_namespace)
          ].uniq.each do |namespace|
            scoped = namespace.foobara_lookup_without_cache(path,
                                                            filter:,
                                                            mode: LookupMode::CHILDREN_ONLY,
                                                            visited:)
            return scoped if scoped
          end

          return nil
        end

        if mode == LookupMode::ABSOLUTE_SINGLE_NAMESPACE
          return foobara_root_namespace.foobara_lookup_without_cache(path,
                                                                     filter:,
                                                                     mode: LookupMode::CHILDREN_ONLY,
                                                                     visited:)
        end

        partial = foobara_registry.lookup(path, filter)

        if mode == LookupMode::DIRECT
          return partial
        end

        if partial
          if partial.scoped_path == path
            return partial
          end
        end

        to_consider = [self]

        if mode != LookupMode::STRICT
          to_consider += foobara_children
        end

        scoped = _lookup_in(path, to_consider, filter:, visited:)

        if scoped
          return scoped
        end

        if (mode == LookupMode::GENERAL || mode == LookupMode::STRICT) && foobara_parent_namespace
          scoped = foobara_parent_namespace.foobara_lookup_without_cache(
            path, filter:, mode: LookupMode::STRICT, visited:
          )

          if scoped
            return scoped
          end
        end

        if mode == LookupMode::GENERAL
          scoped = _lookup_in(path, foobara_depends_on_namespaces, filter:, visited:)

          if scoped
            return scoped
          end
        end

        to_consider = case mode
                      when LookupMode::GENERAL
                        foobara_depends_on_namespaces
                      else
                        []
                      end

        candidates = to_consider.map do |namespace|
          namespace.foobara_lookup_without_cache(path, filter:, mode:, visited:)
        end.compact

        if candidates.size > 1
          # :nocov:
          raise AmbiguousLookupError, "Multiple things matched #{path}"
          # :nocov:
        end

        candidates.first || partial
      end

      def foobara_parent_namespace
        scoped_namespace
      end

      def foobara_lookup!(name, **)
        object = foobara_lookup(name, **)

        unless object
          # :nocov:
          raise NotFoundError, "Could not find #{name}"
          # :nocov:
        end

        object
      end

      def foobara_each(filter: nil, mode: Namespace::LookupMode::GENERAL, &)
        foobara_registry.each_scoped(filter:, &)

        if mode == LookupMode::GENERAL ||
           mode == LookupMode::CHILDREN_ONLY ||
           mode == LookupMode::ABSOLUTE ||
           mode == LookupMode::ABSOLUTE_SINGLE_NAMESPACE
          foobara_children.each do |child|
            child.foobara_each(filter:, mode:, &)
          end
        end

        if mode == Namespace::LookupMode::GENERAL
          foobara_depends_on_namespaces.each do |dependent|
            dependent.foobara_each(filter:, mode:, &)
          end
        end
      end

      def foobara_all(filter: nil, mode: Namespace::LookupMode::GENERAL)
        all = []

        foobara_each(filter:, mode:) do |scoped|
          all << scoped
        end

        all
      end

      def foobara_registered?(path, ...)
        if path.is_a?(Types::Type)
          return false unless path.scoped_path_set?
        end

        !foobara_lookup(path, ...).nil?
      end

      def method_missing(method_name, *, **, &)
        filter, method, bang = _filter_from_method_name(method_name)

        if filter
          method = "foobara_#{method}#{"!" if bang}"
          send(method, *, **, filter:, &)
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
        match = method_name.to_s.match(/^foobara_(lookup|each|all)_(\w+)(!)?$/)

        if match
          filter = foobara_categories[match[2].to_sym]

          if filter
            bang = !match[3].nil?
            method = match[1]

            # only lookup has a bang version
            if !bang || method == "lookup"
              [filter, method, bang]
            end
          end
        else
          match = method_name.to_s.match(/^foobara_(\w+)_registered\?$/)

          if match
            filter = foobara_categories[match[1].to_sym]

            if filter
              [filter, "registered?"]
            end
          end
        end
      end

      def _upgrade_registry(error)
        new_registry_class = case error
                             when Foobara::Namespace::PrefixlessRegistry::RegisteringScopedWithPrefixError
                               Foobara::Namespace::UnambiguousRegistry
                             when Foobara::Namespace::BaseRegistry::WouldMakeRegistryAmbiguousError
                               Foobara::Namespace::AmbiguousRegistry
                             else
                               # :nocov:
                               raise ArgumentError, "Not sure how to upgrade a #{error.class}"
                               # :nocov:
                             end

        old_registry = foobara_registry

        @foobara_registry = new_registry_class.new

        old_registry.each_scoped { |s| foobara_registry.register(s) }
      end

      protected

      def _lookup_in(path, namespaces, filter:, visited:)
        matching_children = []
        last_resort = []

        namespaces.each do |namespace|
          if namespace.scoped_path.empty?
            last_resort << namespace
          else
            match_count = namespace._path_start_match_count(path)

            if match_count > 0
              matching_children << [match_count, namespace]
            end
          end
        end

        matching_children.sort_by(&:first).reverse.each do |(matching_child_score, matching_child)|
          scoped = matching_child.foobara_lookup_without_cache(
            path[matching_child_score..],
            mode: LookupMode::CHILDREN_ONLY,
            filter:,
            visited:
          )

          return scoped if scoped
        end

        last_resort.uniq.each do |namespace|
          scoped = namespace.foobara_lookup_without_cache(path, filter:, mode: LookupMode::CHILDREN_ONLY, visited:)
          return scoped if scoped
        end

        nil
      end

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
