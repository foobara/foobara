module Foobara
  class DomainMapper
    class << self
      def call(value)
        instance.call(value)
      end

      def from(*args)
        if args.empty?
          @from
        else
          if args.size > 1
            # :nocov:
            raise ArgumentError, "only one argument allowed"
            # :nocov:
          end

          @from = args.first
        end
      end

      def to(*args)
        if args.empty?
          @to
        else
          if args.size > 1
            # :nocov:
            raise ArgumentError, "only one argument allowed"
            # :nocov:
          end

          @to = args.first
        end
      end

      def from_type
        return @from_type if defined?(@from_type)

        @from_type = object_to_type(from)
      end

      def to_type
        return @to_type if defined?(@to_type)

        @to_type = object_to_type(to)
      end

      def instance
        @instance ||= new
      end

      def inherited(subclass)
        foobara_domain_mapper_to_process(subclass.instance)

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
            mapper.domain.foobara_domain_mapper(mapper)
          end
          remove_instance_variable(:@foobara_domain_mappers_to_process)
        end
      end

      def domain
        candidate = self

        loop do
          candidate = Util.module_for(candidate)

          if candidate.nil?
            # :nocov:
            raise "Domain mapper must be scoped within a domain but #{self.class.name} is not in a domain"
            # :nocov:
          elsif candidate.foobara_domain?
            return candidate
          end
        end
      end

      def matches?(type_indicator, value)
        return true if type_indicator.nil? || value.nil? || type_indicator == value

        type = object_to_type(type_indicator)

        return true if type.nil? || type == value
        return true if type.applicable?(value) && type.process_value(value).success?

        if value.is_a?(Types::Type)
          if !value.registered? && !type.registered?
            value.declaration_data == type.declaration_data
          end
        else
          value_type = object_to_type(value)

          if value_type
            matches?(type, value_type)
          end
        end
      end

      def object_to_type(object)
        if object
          if object.is_a?(::Class)
            if object < Foobara::Model
              object.model_type
            elsif object < Foobara::Command
              object.inputs_type
            else
              domain.foobara_type_from_declaration(object)
            end
          else
            case object
            when Types::Type
              object
            when ::Symbol
              domain.foobara_lookup_type!(object)
            end
          end
        end
      end
    end

    def from_type
      self.class.from_type
    end

    def to_type
      self.class.to_type
    end

    def call(from_value)
      from_value = from_type.process_value!(from_value)

      mapped_value = map(from_value)

      to_type.process_value!(mapped_value)
    end

    # TODO: can we make _from_value passed to #initialize instead? That way it doesn't have to be passed around
    # between various helper methods
    def map(_from_value)
      # :nocov:
      raise "subclass repsonsibility"
      # :nocov:
    end

    def applicable?(from_value, to_value)
      self.class.matches?(from_type, from_value) && self.class.matches?(to_type, to_value)
    end

    def domain
      self.class.domain
    end
  end
end
