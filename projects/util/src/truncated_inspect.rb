module Foobara
  module TruncatedInspect
    MAX_LENGTH = 200

    def inspect
      instance_vars = instance_variables.map do |var|
        truncate = false

        value = instance_variable_get(var)

        is_array = value.is_a?(::Array)
        is_hash = value.is_a?(::Hash)

        if is_array
          truncate = value.size > 10 || value.any? { |v| v.is_a?(::Array) || v.is_a?(::Hash) }
        elsif is_hash
          truncate = value.size > 10 || value.keys.any? { |k| !k.is_a?(::Symbol) && !k.is_a?(::String) }
          truncate ||= value.values.any? { |v| v.is_a?(::Array) || v.is_a?(::Hash) }
        end

        value = if truncate
                  is_array ? "[...]" : "{...}"
                else
                  value.inspect
                end

        "#{var}=#{value}"
      end

      instance_vars = instance_vars.join(", ")

      result = "#<#{self.class.name}:0x#{object_id.to_s(16)} #{instance_vars}>"

      if result.size > MAX_LENGTH
        result = "#{result[0..(MAX_LENGTH - 5)]}...>"
      end

      result
    end
  end
end
