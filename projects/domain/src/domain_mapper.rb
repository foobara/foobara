module Foobara
  class DomainMapper
    class << self
      def from_type(*args)
        if args.empty?
          @from_type
        else
          if args.size > 1
            raise ArgumentError, "only one argument allowed"
          end

          @from_type = args.first
        end
      end

      def to_type(*args)
        if args.empty?
          @to_type
        else
          if args.size > 1
            raise ArgumentError, "only one argument allowed"
          end

          @to_type = args.first
        end
      end

      def extended(subclass)
        super
      end
    end
  end
end
