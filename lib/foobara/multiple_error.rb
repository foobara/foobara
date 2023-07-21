module Foobara
  class MultipleError < Error
    def initialize(errors, symbol: nil)
      if symbol.nil?
        merge_contexts = true

        symbols = errors.map(&:symbol).uniq
        if symbols.size != 1
          raise "Need to specify a symbol if the errors have mixed symbols"
        end

        symbol = symbols.first
      end

      context = if merge_contexts
                  errors.each_with_object({}) do |error, context|
                    error.context.each_pair do |key, value|
                      value_array = context[key] ||= []
                      Array.wrap(value).each { |v| value_array << v }
                    end
                  end
                else
                  { errors: }
                end

      context.transform_values! do |values|
        values = values.uniq

        values.length == 1 ? values.first : values
      end

      message = errors.map(&:message).map(&:to_s).join(", ")

      super(
        symbol:,
        message:,
        context:
      )
    end
  end
end
