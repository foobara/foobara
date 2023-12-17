module Foobara
  class Error
    class << self
      def types_depended_on(*args)
        set = if args.size == 1
                args.first
              elsif args.empty?
                Set.new
              else
                raise ArgumentError, "Too many arguments #{args}"
              end

        if context_type.registered?
          set << context_type
        else
          context_type.types_depended_on(set)
        end

        set
      end
    end
  end
end
