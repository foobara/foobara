module Foobara
  module Types
    # This will replace Schema...
    # This is like Type
    # Instead of casters/transformers we have can_handle? and desugarizers
    # instead of validators we have declaration validators
    # process:
    #   Make sure we can handle this
    #   desugarize
    #   validate declaration value
    #   transform into Type instance
    # So... sugary type declaration value in, type out
    # TODO: maybe change name to TypeDeclarationProcessor?? That frees up
    # the type declaration value to be known as a type declaration and makes
    # passing it ot the Type maybe a little less awkward.
    class TypeDeclarationHandler < Value::Processor::Pipeline
      include Concerns::TypeBuilding

      attr_accessor :desugarizers, :type_declaration_validators, :to_type_transformers

      def initialize(
        *args,
        to_type_transformers:,
        desugarizers: [],
        type_declaration_validators: [],
        **opts
      )
        self.desugarizers = Array.wrap(desugarizers)
        self.type_declaration_validators = Array.wrap(type_declaration_validators)
        self.to_type_transformers = Array.wrap(to_type_transformers) # why would we need multiple??

        super(*args, **opts)
      end

      def applicable?(sugary_type_declaration)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def processors
        [desugarizer, type_declaration_validator, to_type_transformer]
      end

      def desugarizer
        @desugarizer ||= Value::Processor::Pipeline.new(processors: desugarizers)
      end

      def desugarize(value)
        desugarizer.process!(value)
      end

      def type_declaration_validator
        @type_declaration_validator ||= Value::Processor::Pipeline.new(processors: type_declaration_validators)
      end

      def type_declaration_validation_errors(value)
        value = desugarize(value)
        type_declaration_validator.process(value).errors
      end

      def to_type_transformer
        @to_type_transformer ||= Value::Processor::Pipeline.new(processors: to_type_transformers)
      end

      def to_type(value)
        process(value)
      end
    end
  end
end
