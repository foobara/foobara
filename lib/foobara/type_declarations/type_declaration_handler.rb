module Foobara
  module TypeDeclarations
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
      include WithRegistries

      attr_accessor :desugarizers, :type_declaration_validators

      def initialize(
        *args,
        processors: nil,
        desugarizers: starting_desugarizers,
        type_declaration_validators: starting_type_declaration_validators,
        **opts
      )
        if processors.present?
          raise ArgumentError, "Cannot set processors directly for a type declaration handler"
        end

        self.desugarizers = Array.wrap(desugarizers)
        self.type_declaration_validators = Array.wrap(type_declaration_validators)

        super(*Util.args_and_opts_to_args(args, opts))
      end

      def starting_desugarizers
        # TODO: this is not great because if new stuff gets registered at runtime then we can't really
        # update this cached data easily
        desugarizers = []

        klass = self.class

        until klass == TypeDeclarationHandler
          desugarizers += Util.constant_values(klass, extends: TypeDeclarations::Desugarizer).map(&:instance)
          klass = klass.superclass
        end

        desugarizers
      end

      def starting_type_declaration_validators
        # TODO: this is not great because if new stuff gets registered at runtime then we can't really
        # update this cached data easily
        Util.constant_values(self.class, extends: Value::Validator, inherit: true).map(&:instance)
      end

      def to_type_transformer
        self.class::ToTypeTransformer.instance
      end

      def inspect
        s = super

        if s.size > 400
          "#{s[0..400]}..."
        end
      end

      def applicable?(_sugary_type_declaration)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def processors
        [desugarizer, type_declaration_validator, to_type_transformer]
      end

      def process(raw_type_declaration)
        type_outcome = super(raw_type_declaration.deep_dup)

        if type_outcome.success?
          type_outcome.result.raw_declaration_data = raw_type_declaration
        end

        type_outcome
      end

      def desugarizer
        Value::Processor::Pipeline.new(processors: desugarizers)
      end

      def desugarize(value)
        Value::Processor::Pipeline.new(processors: desugarizers).process!(value)
      end

      def type_declaration_validator
        Value::Processor::Pipeline.new(processors: type_declaration_validators)
      end

      def type_declaration_validation_errors(value)
        value = desugarize(value)
        Value::Processor::Pipeline.new(processors: type_declaration_validators).process(value).errors
      end

      def to_type(value)
        process!(value)
      end
    end
  end
end
