require_relative "scoped"

module Foobara
  class Namespace
    include Scoped

    attr_accessor :accesses, :registry

    def initialize(scoped_name_or_path, acceses: [], parent_namespace: nil)
      if parent_namespace
        self.namespace = parent_namespace
        parent_namespace.children << self
      end

      self.accesses = accesses

      self.scoped_path = if scoped_name_or_path.is_a?(String)
                           scoped_name_or_path.split("::")
                         else
                           scoped_name_or_path
                         end
    end

    def registry
      @registry ||= Foobara::Namespace::PrefixlessRegistry.new
    end

    def children
      @children ||= []
    end

    def root_namespace
      ns = self

      ns = ns.parent_namespace until ns.parent_namespace.nil?

      ns
    end

    def register(scoped)
      begin
        registry.register(scoped)
      rescue Foobara::Namespace::PrefixlessRegistry::RegisteringScopedWithPrefixError,
             Foobara::Namespace::UnambiguousRegistry::WouldMakeRegistryAmbiguousError => e
        upgrade_registry(e)
        return register(scoped)
      end

      # awkward??
      scoped.namespace = self
    end

    def lookup(path, absolute: false)
      if path.is_a?(::String)
        path = path.split("::")
      end

      if path[0] == ""
        return root_namespace.lookup(path[(root_namespace.scoped_path.size + 1)..], absolute: true)
      end

      scoped = registry.lookup(path)
      return scoped if scoped

      accesses&.each do |dependent_namespace|
        object = dependent_namespace.lookup(path)
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
        scoped = matching_child.lookup(path[matching_child_score..], absolute: true)
        return scoped if scoped
      end

      unless absolute
        parent_namespace&.lookup(path)
      end
    end

    def parent_namespace
      namespace
    end

    def lookup!(name)
      object = lookup(name)

      unless object
        raise "Could not find #{name}"
      end

      object
    end

    private

    def upgrade_registry(error)
      new_registry_class = case error
                           when Foobara::Namespace::PrefixlessRegistry::RegisteringScopedWithPrefixError
                             Foobara::Namespace::UnambiguousRegistry
                           when Foobara::Namespace::UnambiguousRegistry::WouldMakeRegistryAmbiguousError
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
