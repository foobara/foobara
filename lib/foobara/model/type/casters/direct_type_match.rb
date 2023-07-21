require "foobara/model/type/caster"

module Foobara
  class Model
    class Type
      module Casters
        class DirectTypeMatchCaster < Caster
          class << self
            def for(type)
              @for ||= {}
              @for[type] ||= new(type)
            end
          end

          def cast_from(value)
            if value.is_a?(ruby_class)
              Outcome.success(value)
            else
              Outcome.errors(
                CannotCastError.new(
                  message: "#{value} is not a #{ruby_class}",
                  context: {
                    cast_to_type: symbol,
                    cast_to_ruby_class: ruby_class,
                    value:
                  }
                )
              )
            end
          end
        end
      end
    end
  end
end
