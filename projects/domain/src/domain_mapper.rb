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

      def inherited(subclass)
        parent = subclass
        domain = nil

        until domain
          parent = Util.module_for(parent)

          if parent.foobara_domain?
            domain = parent
          end
        end

        domain.foobara_domain_mapper_to_process(subclass)

        super
      end
    end

    attr_accessor :from_value

    def call
      raise "subclass responsibility"
    end
  end
end
