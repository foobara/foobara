module Foobara
  module Util
    module_function

    def module_for(mod)
      name = mod.name[/(.*)::/, 1]
      Object.const_get(name) if name
    end

    def power_set(array)
      return [[]] if array.empty?

      head, *tail = array
      subsets = power_set(tail)
      subsets + subsets.map { |subset| [head, *subset] }
    end

    def constant_value(mod, constant)
      if mod.constants(false).include?(constant)
        mod.const_get(constant, false)
      end
    end

    def constant_values(mod, klasses_to_include = nil)
      klasses_to_include = klasses_to_include ? Array.wrap(klasses_to_include) : [Object]

      mod.constants.map { |const| constant_value(mod, const) }.select do |object|
        klasses_to_include.any? { |klass| object.is_a?(klass) }
      end
    end

    def require_directory(directory)
      require_pattern("#{directory}/**/*.rb")
    end

    def require_pattern(glob)
      files = Dir[glob].sort_by(&:length).reverse

      raise "Didn't find anything to require for #{glob}" if files.empty?

      files.each do |f|
        require f
      end
    end
  end
end
