module Foobara
  # NOTE: If you depend_on a domain mapper in a command, then you need to depend on all domain mappers
  # that that command uses. Or you can just exclude all of them in which case Foobara won't enforce
  # explicit depends_on of domain mappers.
  class DomainMapper
    include CommandPatternImplementation

    class << self
      def foobara_on_register
        foobara_domain.new_mapper_registered!
      end

      def map(value)
        new(from: value).run
      end

      def map!(value)
        new(from: value).run!
      end

      # A bit hacky because Command only supports attributes inputs at the moment, ugg.
      def from(...)
        from_type = args_to_type(...)

        inputs do
          from from_type, :required
        end
      end

      def to(...)
        result_type = args_to_type(...)
        result(result_type)
      end

      def from_type
        inputs_type.element_types[:from]
      end

      def to_type
        result_type
      end

      def applicable?(from_value, to_value)
        matches?(from_type, from_value) && matches?(to_type, to_value)
      end

      def matches?(type_indicator, value)
        match_score(type_indicator, value)&.>(0)
      end

      def applicable_score(from_value, to_value)
        [*match_score(from_type, from_value), *match_score(to_type, to_value)].sum
      end

      def match_score(type_indicator, value)
        return 1 if type_indicator.nil? || value.nil?
        return 20 if type_indicator == value

        type = object_to_type(type_indicator)

        return 1 if type.nil?
        return 9 if type == value

        return 5 if type.applicable?(value) && type.process_value(value).success?

        if value.is_a?(Types::Type)
          if !value.registered? && !type.registered?
            if value.declaration_data == type.declaration_data
              8
            end
          end
        else
          value_type = object_to_type(value)

          if value_type
            if matches?(type, value_type)
              6
            end
          end
        end
      end

      # TODO: should this be somewhere more general-purpose?
      def args_to_type(*args, **opts, &block)
        if args.size == 1 && opts.empty? && block.nil?
          object_to_type(args.first)
        else
          domain.foobara_type_from_declaration(*args, **opts, &block)
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

    def execute
      map
    end

    def from
      inputs[:from]
    end

    def map
      # :nocov:
      raise "subclass responsibility"
      # :nocov:
    end
  end
end
