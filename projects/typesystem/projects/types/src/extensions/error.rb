module Foobara
  class Error
    class << self
      def types_depended_on(*args)
        if args.size == 1
          context_type.types_depended_on(args[0])
        elsif args.empty?
          if abstract?
            []
          else
            context_type.types_depended_on
          end
        else
          # simplecov:disable
          raise ArgumentError, "Too many arguments #{args}"
          # simplecov:enable
        end
      end
    end
  end
end
