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
  end
end
