module Foobara
  module Types
    # TODO: move casting interface to here?
    class Type < Value::Processor::Pipeline
      include Concerns::SupportedProcessorRegistration

      class << self
        attr_accessor :root_type
      end

      # Can we eliminate symbol here or no?
      # Has a collection of transformers and validators.
      # transformers return an outcome that might contain a new value
      # validators return error arrays
      # a caster is a special type of transformer expected to happen before all other
      # transformers and validators.
      #
      # let's explore the use-case of attributes processing...
      #
      # 1) validate that it's a hash
      # 2) validate the keys are symbolizable
      # 3) symbolize the keys
      # 4) fill in default values for missing keys
      # 5) for each key in the schemas keys, process each value against its schema
      #    (cast it, transform it, validate it)
      # 5) validate required attributes are present
      # 6) validate there aren't extra keys
      # .
      # Looks like this splits up nicely in to 3 steps... casting, transforming, validating. Unsure if this ordering
      # will always hold so I'm tempted to combine transformers and validators into one collection to be more flexible
      # Although this means it is doing some of the validation as part of the casting steps.
      #
      # What if we don't allow transformers to fail? Then they have to be split into a validator and transformer.
      # then validators give errors and transformers give a new value to replace the prior value.
      # .
      # OK I'll go that route but I think I have to eliminate any idea of pre-defined order based on type.
      #
      # steps are... change casters into processors.
      # ohhhh maybe we should pass them an outcome?? nah. Well... we could make a base class do that? Let's do that.
      #
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
                    :raw_declaration_data

      def initialize(
        *args,
        base_type: self.class.root_type,
        casters: [],
        transformers: [],
        validators: [],
        element_processors: nil,
        element_types: nil,
        structure_count: nil,
        abstract: false,
        **opts
      )
        self.base_type = base_type
        self.casters = Array.wrap(casters)
        self.transformers = transformers
        self.validators = validators
        self.element_processors = element_processors
        self.structure_count = structure_count
        self.element_types = element_types

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
        value_caster.process(value)
      end

      def cast!(value)
        value_caster.process!(value)
      end

      # TODO: an interesting thought... we have Processor and then a subclass of Processor and then an instance of
      # processor that encapsulates the declaration_data for that processor. But then we pass `value` to every
      # method in the instance of the processor as needed. This means it can't really memoize stuff. Should we create
      # an instance of something from the instance of the processor and then ask it questions?? TODO: try this
      def value_transformer
        if transformers.present?
          # TODO: create Transformer::Pipeline. Or not? yagni?
          Value::Processor::Pipeline.new(processors: transformers)
        end
      end

      # TODO: figure out how to safely memoize stuff so like this for performance reasons
      def value_validator
        if validators.present?
          # TODO: create Validator::Pipeline
          Value::Processor::Pipeline.new(processors: validators)
        end
      end

      def element_processor
        if element_processors.present?
          Value::Processor::Pipeline.new(processors: element_processors)
        end
      end

      def validation_errors(value)
        value = cast!(value)
        value = value_transformer.process!(value)
        value_validator.process(value).errors
      end
    end
  end
end
