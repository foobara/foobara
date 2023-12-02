module Foobara
  module Scoped
    attr_writer :scoped_path
    attr_accessor :namespace

    def scoped_path
      @scoped_path || raise("Subclass responsibility")
    end

    def scoped_name=(name)
      @scoped_path = name.split("::")
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
      @scoped_full_name ||= scoped_full_path.join("::")
    end
  end
end
