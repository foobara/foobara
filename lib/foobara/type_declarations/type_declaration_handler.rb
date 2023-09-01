module Foobara
  module TypeDeclarations
    class TypeDeclarationHandler < Value::Processor::Pipeline
      class << self
        def starting_desugarizers
          starting_desugarizers_with_inherited
        end

        def starting_desugarizers_with_inherited
          # TODO: this is not great because if new stuff gets registered at runtime then we can't really
          # update this cached data easily
          if superclass == TypeDeclarationHandler
            starting_desugarizers_without_inherited
          else
            [*superclass.starting_desugarizers, *starting_desugarizers_without_inherited]
          end
        end

        def starting_desugarizers_without_inherited
          # TODO: this is not great because if new stuff gets registered at runtime then we can't really
          # update this cached data easily
          Util.constant_values(self, extends: TypeDeclarations::Desugarizer).map(&:instance)
        end

        def starting_type_declaration_validators
          # TODO: this is not great because if new stuff gets registered at runtime then we can't really
          # update this cached data easily
          Util.constant_values(self, extends: Value::Validator, inherit: true).map(&:instance)
        end
      end

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
          # :nocov:
          raise ArgumentError, "Cannot set processors directly for a type declaration handler"
          # :nocov:
        end

        self.desugarizers = Array.wrap(desugarizers)
        self.type_declaration_validators = Array.wrap(type_declaration_validators)

        super(*Util.args_and_opts_to_args(args, opts))
      end

      delegate :starting_desugarizers,
               :starting_desugarizers_with_inherited,
               :starting_desugarizers_without_inherited,
               :starting_type_declaration_validators,
               to: :class

      def to_type_transformer
        self.class::ToTypeTransformer.instance
      end

      def inspect
        # :nocov:
        s = super

        if s.size > 400
          s = "#{s[0..400]}..."
        end

        s
        # :nocov:
      end

      def applicable?(_sugary_type_declaration)
        # :nocov:
        raise "subclass responsibility"
        # :nocov:
      end

      def processors
        [desugarizer, type_declaration_validator, to_type_transformer]
      end

      def process_value(raw_type_declaration)
        super(raw_type_declaration.deep_dup).tap do |type_outcome|
          if type_outcome.success?
            type_outcome.result.raw_declaration_data = raw_type_declaration
          end
        end
      end

      def desugarizer
        Value::Processor::Pipeline.new(processors: desugarizers)
      end

      def desugarize(value)
        Value::Processor::Pipeline.new(processors: desugarizers).process_value!(value)
      end

      def type_declaration_validator
        Value::Processor::Pipeline.new(processors: type_declaration_validators)
      end

      alias to_type process_value!
    end
  end
end
