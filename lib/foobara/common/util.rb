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

    def args_and_opts_to_opts(args, opts)
      if !args.is_a?(Array) || args.size > 1
        raise ArgumentError, "args must be an array of 0 or 1 hashes but received #{args}"
      end

      unless opts.is_a?(Hash)
        raise ArgumentError, "opts must be a hash not a #{opts}"
      end

      (args.first || {}).merge(opts)
    end

    def arg_and_opts_to_arg(arg, opts)
      if arg.present?
        if opts.present?
          unless opts.is_a?(Hash)
            raise ArgumentError, "opts must be a hash not a #{opts}"
          end

          unless arg.is_a?(Hash)
            raise ArgumentError, "arg must be a hash if present when opts is present"
          end

          arg.merge(opts)
        else
          arg
        end
      else
        opts.presence
      end
    end

    # Strange utility method here...
    # idea is there's a method that takes 0 or 1 arguments which may or may not be a hash.
    # To make sure we don't act like there's an argument when there's not or fail to combine
    # parts of the hash that wind up in opts, this method comines it into an array of 0 or 1
    # argument with stuff merged into the argument if needed.
    def args_and_opts_to_args(args, opts)
      unless args.is_a?(Array)
        raise ArgumentError, "args must be an array of 0 or 1 hashes but received #{args}"
      end

      case args.size
      when 0
        Array.wrap(arg_and_opts_to_arg(args.first, opts))
      when 1
        # Do not go from 1 argument to 0. ie, [nil] should return [nil] not [].
        [arg_and_opts_to_arg(args.first, opts)]
      else
        raise ArgumentError, "args must be an array of 0 or 1 hashes but received #{args}"
      end
    end
  end
end
