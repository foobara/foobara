module Foobara
  module Scoped
    class NoScopedPathSetError < StandardError; end

    attr_reader :scoped_namespace

    def scoped_path
      unless defined?(@scoped_path)
        # :nocov:
        raise NoScopedPathSetError, "No scoped path set. Explicitly set it to nil if that's what you want."
        # :nocov:
      end

      @scoped_path
    end

    def scoped_namespace=(scoped_namespace)
      @scoped_namespace = scoped_namespace
      @scoped_ignore_modules = @scoped_full_name = @scoped_full_path = nil
    end

    def scoped_name=(name)
      name = name.to_s if name.is_a?(::Symbol)
      @scoped_path = name.split("::")
    end

    def scoped_path=(path)
      @scoped_path = path.map(&:to_s)
    end

    def scoped_path_autoset=(bool)
      @scoped_path_autoset = bool
    end

    def scoped_path_autoset?
      @scoped_path_autoset
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
      @scoped_full_path ||= [*scoped_namespace&.scoped_full_path, *scoped_path]
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
      defined?(@scoped_path)
    end

    def scoped_ignore_module?(mod)
      @scoped_ignore_modules&.include?(mod) || scoped_namespace&.scoped_ignore_module?(mod)
    end

    def scoped_ignore_modules=(modules)
      mods = @scoped_ignore_modules || []
      @scoped_ignore_modules = [*mods, *modules]
    end
  end
end
