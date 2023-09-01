module Foobara
  module Types
    # TODO: move casting interface to here?
    class Type < Value::Processor::Pipeline
      include Concerns::SupportedProcessorRegistration

      class << self
        attr_accessor :root_type
      end

      # notes: needed/useful transformers/validators to implement:
      #
      # default (cast from nil at attribute level)
      # required (validation at attributes level)
      # allow_empty (validation at attribute level)
      # allow_nil (validation at attribute level)
      # one_of (validation at attribute level)
      # max_length (string validation at attribute level)
      # max (integer validation at attribute level)
      # matches (string against a regex)

      attr_accessor :base_type,
                    :casters,
                    :transformers,
                    :validators,
                    :element_processors,
                    :structure_count,
                    :element_types,
                    :element_type,
                    :raw_declaration_data,
                    :name

      def initialize(
        *args,
        base_type: self.class.root_type,
        name: :anonymous,
        casters: [],
        transformers: [],
        validators: [],
        element_processors: nil,
        element_type: nil,
        element_types: nil,
        structure_count: nil,
        **opts
      )
        self.base_type = base_type
        self.casters = Array.wrap(casters)
        self.transformers = transformers
        self.validators = validators
        self.element_processors = element_processors
        self.structure_count = structure_count
        self.element_types = element_types
        self.element_type = element_type
        self.name = name

        super(
          *args,
          **opts.merge(processors:, prioritize: false)
        )
      end

      def processors
        [
          base_type,
          value_caster,
          value_transformer,
          value_validator,
          element_processor
        ].compact
      end

      def value_caster
        Value::Processor::Casting.new({ cast_to: declaration_data }, casters:)
      end

      def cast(value)
        value_caster.process_value(value)
      end

      def cast!(value)
        value_caster.process_value!(value)
      end

      # TODO: an interesting thought... we have Processor and then a subclass of Processor and then an instance of
      # processor that encapsulates the declaration_data for that processor. But then we pass `value` to every
      # method in the instance of the processor as needed. This means it can't really memoize stuff. Should we create
      # an instance of something from the instance of the processor and then ask it questions?? TODO: try this
      def value_transformer
        if transformers.present?
          Value::Processor::Pipeline.new(processors: transformers)
        end
      end

      # TODO: figure out how to safely memoize stuff so like this for performance reasons
      # A good way, but potentially a decent amount of work, is to have a class that takes value to its initialize
      # method.
      def value_validator
        if validators.present?
          Value::Processor::Pipeline.new(processors: validators)
        end
      end

      def element_processor
        if element_processors.present?
          Value::Processor::Pipeline.new(processors: element_processors)
        end
      end

      # TODO: some way of memoizing these values? Would need to introduce a new class that takes the value to its
      # constructor
      def validation_errors(value)
        value = cast!(value)
        if value_transformer
          value = value_transformer.process_value!(value)
        end

        if value_validator
          value_validator.process_value(value).errors
        else
          []
        end
      end
    end
  end
end
