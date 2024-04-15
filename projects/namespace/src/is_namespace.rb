require_relative "scoped"

module Foobara
  class Namespace
    module IsNamespace
      include Scoped

      def foobara_parent_namespace=(namespace)
        self.scoped_namespace = namespace
        scoped_namespace.foobara_children << self if namespace
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

      def foobara_register(scoped)
        foobara_registry.register(scoped)
        # awkward??
        scoped.scoped_namespace = self
      rescue PrefixlessRegistry::RegisteringScopedWithPrefixError,
             BaseRegistry::WouldMakeRegistryAmbiguousError => e
        _upgrade_registry(e)
        foobara_register(scoped)
      end

      def foobara_unregister(scoped)
        foobara_registry.unregister(scoped)
        scoped.scoped_namespace = nil
      end

      def foobara_lookup(
        path,
        filter: nil,
        mode: LookupMode::GENERAL,
        visited: Set.new
      )
        visited_key = [path, mode, self]
        return nil if visited.include?(visited_key)

        visited << visited_key

        LookupMode.validate!(mode)

        path = Namespace.to_registry_path(path)

        if mode == LookupMode::RELAXED
          scoped = foobara_lookup(
            path,
            filter:,
            mode: LookupMode::GENERAL,
            visited:
          )
          return scoped if scoped

          candidates = foobara_children.map do |namespace|
            namespace.foobara_lookup(path, filter:, mode:, visited:)
          end.compact

          if candidates.size > 1
            # :nocov:
            raise AmbiguousNameError,
                  "#{path} is ambiguous. Matches the following: #{candidates.map(&:scoped_full_name)}"
            # :nocov:
          end

          return candidates.first || foobara_parent_namespace&.foobara_lookup(path, filter:, mode:, visited:)
        end

        if path[0] == ""
          if mode == LookupMode::DIRECT
            return nil unless scoped_full_name == ""

            path = path[1..]
          else
            path = path[(foobara_root_namespace.scoped_path.size + 1)..]
          end

          return foobara_root_namespace.foobara_lookup(path, filter:, mode: LookupMode::ABSOLUTE)
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
        return scoped if scoped

        if [LookupMode::GENERAL, LookupMode::STRICT].include?(mode) && foobara_parent_namespace
          scoped = foobara_parent_namespace.foobara_lookup(path, filter:, mode: LookupMode::STRICT, visited:)
          return scoped if scoped
        end

        scoped = _lookup_in(path, foobara_depends_on_namespaces, filter:, visited:)
        return scoped if scoped

        to_consider = case mode
                      when LookupMode::GENERAL
                        foobara_depends_on_namespaces
                      else
                        []
                      end

        candidates = to_consider.map do |namespace|
          namespace.foobara_lookup(path, filter:, mode:, visited:)
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

        return if mode == Namespace::LookupMode::DIRECT

        if mode == Namespace::LookupMode::GENERAL
          foobara_children.each do |child|
            child.foobara_each(filter:, mode:, &)
          end
        end

        foobara_depends_on_namespaces.each do |dependent|
          dependent.foobara_each(filter:, mode:, &)
        end
      end

      def foobara_all(filter: nil, mode: Namespace::LookupMode::GENERAL)
        all = []

        foobara_each(filter:, mode:) do |scoped|
          all << scoped
        end

        all
      end

      def foobara_registered?(...)
        !foobara_lookup(...).nil?
      end

      def method_missing(method_name, *, **, &)
        filter, method, bang = _filter_from_method_name(method_name)

        if filter
          method = "foobara_#{method}#{bang ? "!" : ""}"
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
          scoped = matching_child.foobara_lookup(
            path[matching_child_score..],
            mode: LookupMode::ABSOLUTE,
            filter:,
            visited:
          )

          return scoped if scoped
        end

        last_resort.uniq.each do |namespace|
          scoped = namespace.foobara_lookup(path, filter:, mode: LookupMode::ABSOLUTE, visited:)
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
