module Foobara
  class Error
    class << self
      def types_depended_on(*args)
        if args.size == 1
          context_type.types_depended_on(args.first)
        elsif args.empty?
          context_type.types_depended_on
        else
          # :nocov:
          raise ArgumentError, "Too many arguments #{args}"
          # :nocov:
        end
      end
    end
  end
end
