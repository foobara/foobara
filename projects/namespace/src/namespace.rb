require_relative "scoped"

module Foobara
  class Namespace
    include Scoped

    class NotFoundError < StandardError; end

    attr_accessor :accesses

    def initialize(scoped_name_or_path, accesses: [], parent_namespace: nil)
      if parent_namespace
        self.namespace = parent_namespace
        parent_namespace.children << self
      end

      self.accesses = Util.array(accesses)

      self.scoped_path = if scoped_name_or_path.is_a?(String)
                           scoped_name_or_path.split("::")
                         else
                           scoped_name_or_path
                         end
    end

    def add_category(symbol, proc)
      @categories = categories.merge(symbol.to_sym => proc)
    end

    def add_category_for_instance_of(symbol, klass)
      add_category(symbol, proc { is_a?(klass) })
    end

    def add_category_for_subclass_of(symbol, klass)
      add_category(symbol, proc { self < klass })
    end

    def categories
      @categories ||= parent_namespace&.categories || {}
    end

    def registry
      @registry ||= Foobara::Namespace::PrefixlessRegistry.new
    end

    def children
      @children ||= []
    end

    def root_namespace
      ns = self

      ns = ns.parent_namespace until ns.root?

      ns
    end

    def root?
      parent_namespace.nil?
    end

    def register(scoped)
      begin
        registry.register(scoped)
      rescue PrefixlessRegistry::RegisteringScopedWithPrefixError,
             BaseRegistry::WouldMakeRegistryAmbiguousError => e
        upgrade_registry(e)
        return register(scoped)
      end

      # awkward??
      scoped.namespace = self
    end

    def lookup(path, absolute: false, filter: nil)
      if path.is_a?(::String)
        path = path.split("::")
      end

      if path[0] == ""
        return root_namespace.lookup(path[(root_namespace.scoped_path.size + 1)..], absolute: true, filter:)
      end

      scoped = registry.lookup(path, filter)
      return scoped if scoped

      accesses&.each do |dependent_namespace|
        object = dependent_namespace.lookup(path, filter:)
        return object if object
      end

      matching_child = nil
      matching_child_score = 0

      to_consider = absolute ? children : [self, *children]

      to_consider.each do |namespace|
        match_count = namespace._path_start_match_count(path)

        if match_count > matching_child_score
          matching_child = namespace
          matching_child_score = match_count
        end
      end

      if matching_child
        scoped = matching_child.lookup(path[matching_child_score..], absolute: true, filter:)
        return scoped if scoped
      end

      unless absolute
        parent_namespace&.lookup(path, filter:)
      end
    end

    def parent_namespace
      namespace
    end

    def lookup!(name, filter: nil)
      object = lookup(name, filter:)

      unless object
        # :nocov:
        raise NotFoundError, "Could not find #{name}"
        # :nocov:
      end

      object
    end

    def method_missing(method_name, *)
      filter, bang = filter_from_method_name(method_name)

      if filter
        if bang
          lookup!(*, filter:)
        else
          lookup(*, filter:)
        end
      else
        # :nocov:
        super
        # :nocov:
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      !!filter_from_method_name(method_name) || super
    end

    private

    def filter_from_method_name(method_name)
      match = method_name.to_s.match(/^lookup_(\w+)(!)?$/)

      if match
        filter = categories[match[1].to_sym]
        if filter
          bang = !match[2].nil?

          [filter, bang]
        end
      end
    end

    def upgrade_registry(error)
      new_registry_class = case error
                           when Foobara::Namespace::PrefixlessRegistry::RegisteringScopedWithPrefixError
                             Foobara::Namespace::UnambiguousRegistry
                           when Foobara::Namespace::BaseRegistry::WouldMakeRegistryAmbiguousError
                             Foobara::Namespace::AmbiguousRegistry
                           end

      old_registry = registry

      @registry = new_registry_class.new

      old_registry.each_scoped { |s| registry.register(s) }
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
