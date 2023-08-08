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
      if mod.constants(false).include?(constant.to_sym)
        mod.const_get(constant, false)
      end
    end

    def constant_values(mod, is_a: nil, extends: nil)
      is_a = Array.wrap(is_a)
      extends = Array.wrap(extends)

      mod.constants.map { |const| constant_value(mod, const) }.select do |object|
        (is_a.blank? || is_a.any? { |klass| object.is_a?(klass) }) &&
          (extends.blank? || (object.is_a?(Class) && extends.any? { |klass| object.ancestors.include?(klass) }))
      end
    end

    def require_directory(directory)
      require_pattern("#{directory}/**/*.rb")
    end

    def require_pattern(glob)
      files = Dir[glob].sort_by(&:length).reverse

      if files.empty?
        # TODO: raise real error
        raise "Didn't find anything to require for #{glob}"
      end

      files.each do |f|
        require f
      end
    end

    def all_symbolic_keys?(hash)
      all_symbolic_elements?(hash.keys)
    end

    def all_symbolizable_keys?(hash)
      all_symbolizable_elements?(hash.keys)
    end

    def all_symbolic_elements?(array)
      array.all? { |key| key.is_a?(Symbol) || key.is_a?(String) }
    end

    def all_symbolizable_elements?(array)
      array.all? { |key| key.is_a?(Symbol) || key.is_a?(String) }
    end
  end
end
