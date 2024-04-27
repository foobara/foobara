module Foobara
  class DomainMapper
    class << self
      def from(*args)
        if args.empty?
          @from
        else
          if args.size > 1
            raise ArgumentError, "only one argument allowed"
          end

          @from = args.first
        end
      end

      def to(*args)
        if args.empty?
          @to
        else
          if args.size > 1
            raise ArgumentError, "only one argument allowed"
          end

          @to = args.first
        end
      end

      def instance
        @instance ||= new
      end

      def inherited(subclass)
        foobara_domain_mapper_to_process(subclass)

        super
      end

      def foobara_domain_mapper_to_process(mapper)
        foobara_domain_mappers_to_process << mapper
      end

      def foobara_domain_mappers_to_process
        @foobara_domain_mappers_to_process ||= []
      end

      def foobara_process_domain_mappers
        if defined?(@foobara_domain_mappers_to_process)
          @foobara_domain_mappers_to_process.each do |mapper|
            domain.foobara_domain_mapper(mapper)
          end
          remove_instance_variable(:@foobara_domain_mappers_to_process)
        end
      end

      def domain
        parent = subclass
        domain = nil

        until domain
          parent = Util.module_for(parent)

          if parent.foobara_domain?
            return domain
          end
        end

        nil
      end
    end

    def from_type
      return @from_type if defined?(@from_type)

      @from_type = object_to_type(self.class.from)
    end

    def to_type
      return @to_type if defined?(@to_type)

      @to_type = object_to_type(self.class.to)
    end

    def call(from_value)
      mapped_value = map(from_value)

      if to_type
        to_type.process_value!(mapped_value)
      else
        mapped_value
      end
    end

    def map(_from_value)
      raise "subclass repsonsibility"
    end

    private

    def object_to_type(object)
      if object
        if object.is_a?(::Class)
          if object < Foobara::Model
            object.model_type
          elsif object < Foobara::Command
            object.inputs_type
          end
        else
          case object
          when Types::Type
            object
          when ::Symbol
            foobara_lookup_type!(to_type)
          end
        end
      end
    end
  end
end
