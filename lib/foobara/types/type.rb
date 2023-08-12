module Foobara
  module Types
    # TODO: move casting interface to here?
    class Type < Value::Processor
      include Value::Processor::Pipeline::Methods
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

      def initialize(
        *args,
        base_type: self.class.root_type,
        casters: [],
        value_transformers: [],
        value_validators: [],
        **opts
      )
        self.base_type = base_type
        self.casters = Array.wrap(casters)
        self.value_transformers = value_transformers
        self.value_validators = value_validators

        super(
          *args,
          **opts.merge(processors:)
        )
      end

      attr_accessor :base_type, :casters, :value_transformers, :value_validators

      def possible_errors
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def processors
        [
          value_caster,
          value_transformer,
          value_validator
        ]
      end

      def value_caster
        @value_caster ||= Value::CastingProcessor.new(casters:)
      end

      def cast(value)
        value_caster.process(value)
      end

      def cast!(value)
        value_caster.process!(value)
      end

      def value_transformer
        # TODO: create Transformer::Pipeline
        @value_transformer ||= Value::Processor::Pipeline.new(processors: value_transformers)
      end

      def value_validator
        # TODO: create Validator::Pipeline
        @value_validator ||= Value::Processor::Pipeline.new(processors: value_validators)
      end

      def validation_errors(value)
        value = cast!(value)
        value = value_transformer.process!(value)
        value_validator.process(value).errors
      end
    end
  end
end
