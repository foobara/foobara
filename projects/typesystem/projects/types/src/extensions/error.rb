module Foobara
  class Error
    class << self
      def types_depended_on(*args)
        if args.size == 1
          context_type.types_depended_on(args.first)
        elsif args.empty?
          begin
            if context_type
              context_type.types_depended_on
            else
              raise Foobara::TypeDeclarations::ErrorExtension::NoContextTypeSetError
            end
          rescue Foobara::TypeDeclarations::ErrorExtension::NoContextTypeSetError
            if abstract?
              []
            else
              # :nocov:
              raise
              # :nocov:
            end
          end

        else
          # :nocov:
          raise ArgumentError, "Too many arguments #{args}"
          # :nocov:
        end
      end
    end
  end
end
