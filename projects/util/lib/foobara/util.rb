module Foobara
  module Util
    module_function

    def require_directory(directory)
      require_pattern("#{directory}/**/*.rb")
    end

    def require_pattern(glob)
      files = Dir[glob].sort_by(&:length).reverse

      if files.empty?
        # :nocov:
        raise "Didn't find anything to require for #{glob}"
        # :nocov:
      end

      files.each do |f|
        require f
      end
    end
  end

  load_project(__dir__)
end
