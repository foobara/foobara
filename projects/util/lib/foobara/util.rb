module Foobara
  module Util
    module_function

    def require_directory(directory)
      require_pattern("#{directory}/**/*.rb")
    end

    def require_pattern(glob)
      files = Dir[glob]

      if files.empty?
        # :nocov:
        raise "Didn't find anything to require for #{glob}"
        # :nocov:
      end

      files.sort_by { |file| [file.count("/"), file.length] }.reverse.each do |f|
        require f
      end
    end
  end
end
