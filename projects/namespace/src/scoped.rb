module Foobara
  module Scoped
    class NoScopedPathSetError < StandardError; end

    attr_reader :namespace
    attr_accessor :default_namespace

    def scoped_path
      @scoped_path || raise(NoScopedPathSetError, "No scoped path set")
    end

    def namespace=(namespace)
      @namespace = namespace
      @ignore_modules = @scoped_full_name = @scoped_full_path = nil
    end

    def scoped_name=(name)
      name = name.to_s if name.is_a?(::Symbol)
      @scoped_path = name.split("::")
    end

    def scoped_path=(path)
      @scoped_path = path.map(&:to_s)
    end

    def scoped_short_name
      @scoped_short_name ||= scoped_path.last
    end

    def scoped_short_path
      @scoped_short_path ||= [scoped_short_name]
    end

    def scoped_name
      @scoped_name ||= scoped_path.join("::")
    end

    def scoped_full_path
      @scoped_full_path ||= [*namespace&.scoped_full_path, *scoped_path]
    end

    def scoped_full_name
      @scoped_full_name ||= "::#{scoped_full_path.join("::")}"
    end

    def scoped_prefix
      return @scoped_prefix if defined?(@scoped_prefix)

      @scoped_prefix = unless scoped_path.size == 1
                         scoped_path[0..-2]
                       end
    end

    def scoped_path_set?
      scoped_path
      true
    rescue Scoped::NoScopedPathSetError
      false
    end

    def ignore_module?(mod)
      @ignore_modules&.include?(mod) || namespace&.ignore_module?(mod)
    end

    def ignore_modules=(modules)
      mods = @ignore_modules || []
      @ignore_modules = [*mods, *modules]
    end
  end
end
