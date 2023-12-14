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
        @foobara_categories = foobara_categories.merge(symbol.to_sym => block)
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

      def foobara_lookup(path, absolute: false, filter: nil, lookup_in_children: true)
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

        if lookup_in_children
          matching_child = nil
          matching_child_score = 0
          last_resort = []

          to_consider = absolute ? foobara_children : [self, *foobara_children]

          to_consider.each do |namespace|
            if namespace.scoped_path.empty?
              last_resort << namespace
            else
              match_count = namespace._path_start_match_count(path)

              if match_count > matching_child_score
                matching_child = namespace
                matching_child_score = match_count
              end
            end
          end

          if matching_child
            scoped = matching_child.foobara_lookup(path[matching_child_score..], absolute: true, filter:)
            return scoped if scoped
          else
            last_resort.each do |namespace|
              scoped = namespace.foobara_lookup(path, absolute: true, filter:)
              return scoped if scoped
            end
          end
        end

        unless absolute
          foobara_parent_namespace&.foobara_lookup(path, filter:)
        end
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

      def foobara_each(filter: nil, lookup_in_children: true, &)
        foobara_registry.each_scoped(filter:, &)

        if lookup_in_children
          foobara_children.each do |child|
            child.foobara_each(filter:, &)
          end
        end
      end

      def foobara_all(filter: nil, lookup_in_children: true)
        all = []

        foobara_each(filter:, lookup_in_children:) do |scoped|
          all << scoped
        end

        all
      end

      def foobara_registered?(name, filter: nil, lookup_in_children: true)
        !foobara_lookup(name, filter:, lookup_in_children:).nil?
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
